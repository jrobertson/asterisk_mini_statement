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
                 telno: 'unknown', outgoing_regex: /SIP\/(\d+)@sipgate,30,tr/)

    sdate = Date.parse startdate
    edate = Date.parse enddate
    
    s = File.read cdr_file

    headings = %i(accountcode src dst dcontet clid channel dstchannel
           lastapp lastdata start answer end duration billsec disposition
                                                               amaflags astid)

    a = s.lines.map {|line| Hash[headings.zip(CSV.parse(line).first)] }


    a2 = a.select do |x|
      date = Date.parse(x[:start])
      date >= sdate and date <= edate and \
          x[:disposition] == 'ANSWERED' and x[:lastapp] == 'Dial'
    end

    a3 = a2.group_by {|x| Date.parse(x[:start]) }

    px = Polyrex.new('calls[telno, period]/day[date]/item[time, telno,' + 
                                                                   ' io, dur]')

    px.summary.period = "%s - %s" % [sdate.strftime("%d/%m/%Y"), 
                                     edate.strftime("%d/%m/%Y")]
    px.summary.telno = telno

    a3.each do |day, items|

      px.create_day({date: day.strftime("%d-%b-%Y")}) do |create|

        items.each do |x|

          outgoing = x[:lastdata][outgoing_regex,1]

          io, telno = if outgoing then
            io = ['out', outgoing]
          else
            telno = ['in', x[:clid][/"([^"]+)/,1]]
          end

          raw_a = Subunit.new(units={minutes:60, hours:60}, 
                                    seconds: x[:duration].to_i).to_a

          a = raw_a.zip(%w(h m s)).inject([]) do |r, x|
            val, label = x
            val > 0 ? r << (val.to_s + label) : r
          end.take 2

          time =  x[:start][/\d{2}:\d{2}/]
          create.item(time: time, telno: telno, io: io, dur: a.join(' ') )
        end

      end

    end
    
    @to_px = px
    @to_xml = px.to_xml pretty: true
    
    title = 'Telephone mini-statement'

    summary = "
#{title}
#{'=' * title.length}

telno: #{px.summary.telno}
Period: #{px.summary.period}

Breakdown:

Date/time  Telephone    duration
=========  ===========  ========"

    records = px.records.inject('') do |r, day|
      date = Date.parse(day.date)
      r << "\n" + date.strftime("%A #{date.day.ordinalize} %B %Y") + "\n\n"

      day.records.inject(r) do |r2, x|

        r2 << (x.io == 'in' ? '>' : '<')
        r2 << Time.parse(x.time).strftime(" %l:%M%P: ")
        r2 << x.telno.ljust(13)
        r2 << x.dur.rjust(8) + "\n"
      end

      r << "\n" + '-' * 32 + "\n"
    end

    @to_s = [summary,records].join("\n")        

  end
  
end
