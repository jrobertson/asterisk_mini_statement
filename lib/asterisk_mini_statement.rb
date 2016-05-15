#!/usr/bin/env ruby

# file: asterisk_mini_statement.rb


require 'csv'
require 'polyrex'
require 'subunit'

class AsteriskMiniStatement

  attr_reader :to_xml

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
      date >= sdate and date <= edate and x[:disposition] == 'ANSWERED'
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

          create.item(time: x[:start], telno: telno, io: io, dur: a.join(' ') )
        end

      end

    end

    @to_xml = px.to_xml pretty: true

  end

end

