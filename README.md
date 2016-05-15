# Introducing the Asterisk_mini_statement gem

    require 'asterisk_mini_statement'


    h = {
      telno: '0131 357 5xxx',
      startdate: '8-May-2016', 
      enddate: '14-May-2016',
      outgoing_regex: /SIP\/(\d+)@voipfone/
    }

    ams = AsteriskMiniStatement.new('/home/james/Master.csv', h)
    puts ams.to_s

The above script will read the Asterisk Call Detail Records (CDR) file and output a listing of inbound and outbound calls over the past week. A sample of the output is show below:


<pre>
Telephone mini-statement
========================

telno: 0131 357 5xxx
Period: 08/05/2016 - 14/05/2016

Breakdown:

Date/time  Telephone    duration
=========  ===========  ========

Sunday 8th May 2016

&gt;  5:29pm: 0751960xxxx     8m 5s

--------------------------------

Monday 9th May 2016

&gt;  8:54am: 013122xxxxx       55s
&gt;  3:09pm: 013151xxxxx    1m 22s

--------------------------------

Tuesday 10th May 2016

&gt;  4:55pm: 075900xxxxx       57s
&lt;  4:58pm: 013177xxxxx    1m 11s

--------------------------------

Wednesday 11th May 2016

&gt;  4:02pm: 013166xxxxx       26s

--------------------------------

Thursday 12th May 2016

&gt;  3:40pm: 077863xxxxx       35s
&gt;  3:41pm: 013166xxxxx       37s

--------------------------------

Friday 13th May 2016

&gt;  2:08pm: 013155xxxxx       50s
&lt;  3:49pm: 013151xxxxx       47s
&gt;  3:57pm: 013151xxxxx    1m 37s
&lt;  3:59pm: 013155xxxxx     2m 9s

--------------------------------
</pre>

Notes:

* The outgoing_regex parameter is necessary to identify from the lastdata field if the call was an outgoing call or not
* The output is designed for printing to a mini-thermal printer (32 characters wide).

## Resources

* asterisk_mini_statement https://rubygems.org/gems/asterisk_mini_statement

asterisk cdr csv statement ministatement
