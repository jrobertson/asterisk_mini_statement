#!/usr/bin/env ruby

# file: asterisk_mini_statement.rb


require 'csv'
require 'polyrex'
require 'subunit'

module DateEnhanced
  
  refine Fixnum do
    def ordinalize()
      self.to_s + ( (10...20).include?(self) ? 'th' : 
                %w{ th st nd rd th th th th th th }[self % 10] )
    end      
  end
end

class AsteriskMiniStatement
  using DateEnhanced
  
  attr_reader :to_xml, :to_px, :to_s

  def initialize(cdr_file='/var/log/asterisk/cdr-csv/Master.csv', 
                  startdate: (Date.today - 8).strftime("%d-%b-%Y"),
                    enddate: (Date.today - 1).strftime("%d-%b-%Y"),
                 telno: 'unknown', outgoing_regex: /SIP\/(\d+)@/)

    sdate,  edate = [startdate, enddate].map {|x| Date.parse x}
    s = File.read cdr_file    
    
    headings = %i(accountcode src dst dcontet clid channel dstchannel
           lastapp lastdata start answer end duration billsec disposition
                                                               amaflags astid)

    lines = s.lines.map {|line| Hash[headings.zip(CSV.parse(line).first)] }


    lines.select! do |x|
      date = Date.parse(x[:start])
      date >= sdate and date <= edate and  x[:lastapp] == 'Dial'
    end

    days = lines.group_by {|x| Date.parse(x[:start]) }

    px = Polyrex.new('calls[telno, period]/day[date]/item[time, telno,' + 
                                                                   ' io, dur]')
    px.summary.telno = telno    
    px.summary.period = "%s - %s" % [sdate, edate].\
                                        map{|x| x.strftime("%d/%m/%Y") }
                                     
    
    days.each do |day, items|

      px.create_day({date: day.strftime("%d-%b-%Y")}) do |create|

        items.each do |x|

          outgoing = x[:lastdata][outgoing_regex,1]

          io, telno = outgoing ? ['out', outgoing] : 
                                        ['in', x[:clid][/"([^"]+)/,1]]

          raw_a = Subunit.new(units={minutes:60, hours:60}, 
                                    seconds: x[:duration].to_i).to_a

          a = raw_a.zip(%w(h m s)).inject([]) do |r, x|
            val, label = x
            val > 0 ? r << (val.to_s + label) : r
          end.take 2

          create.item(time: x[:start][/\d{2}:\d{2}/], telno: telno, 
                      io: io, dur: a.join(' ') )
        end

      end

    end
    
    @to_px = px
    @to_xml = px.to_xml pretty: true
    
    title = 'Telephone mini-statement'

    s = "
#{title}
#{'=' * title.length}

telno: #{px.summary.telno}
Period: #{px.summary.period}

Breakdown:

Date/time  Telephone    duration
=========  ===========  ========
"

    px.records.inject(s) do |r, day|
      
      date = Date.parse(day.date)
      r << "\n" + date.strftime("%A #{date.day.ordinalize} %B %Y") + "\n\n"

      day.records.inject(r) do |r2, x|

        r2 << (x.io == 'in' ? '>' : '<') + \
          Time.parse(x.time).strftime(" %l:%M%P: ") + \
          x.telno.ljust(13) + x.dur.rjust(8) + "\n"
      end

      r << "\n" + '-' * 32 + "\n"
    end

    @to_s = s        

  end
  
end