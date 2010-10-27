gawk -v date_format=$1 -v delta_time=$2 -v app=$3 -v action="$4" -v mode="$5" -v request_status=$6 '
function round(x,   ival, aval, fraction)
{
  ival = int(x)    # integer part, int() truncates

  if (ival == x)   # no fraction
    return ival   # ensure no decimals

  if (x < 0) {
    aval = -x     # absolute value
    ival = int(aval)
    fraction = aval - ival
    if (fraction >= .5)
      return int(x) - 1   # -2.5 --> -3
    else
      return int(x)       # -2.3 --> -2
  } else {
    fraction = x - ival
    if (fraction >= .5)
      return ival + 1
    else
      return ival
  }
}
BEGIN{
  action_regexp="^"action"$"
  now_time = systime()
  now_date = strftime(date_format, now_time)
  begin_time = now_time - delta_time
  count = 0
  count_fine = 0
  count_normal = 0
  count_bad = 0

  quantils[0] = 95
  quantils[1] = 98
  quantils[2] = 99
  quantils[3] = 99.5
  quantils[4] = 99.9
}
{
  # example log entry
  # hh-favresumes PUT /resume/open/1282694867?empinfo=emp(1282694862),mng(1282694865) HTTP/1.1 0.106 1288686990.805 200
  match($0, /([^ ]+) (GET|POST|PUT|DELETE) ([^?]+)[^ ]+ HTTP\/[^ ]+ ([^ ]+) ([^ ]+) ([^ ]+)/, matches)

  log_entry_app = matches[1]
  if(log_entry_app != app)
    next

  log_time = matches[5]
  if(log_time <= begin_time)
    next

  url = matches[3]
  if(match(url, action_regexp) == 0)
    next

  status = matches[2]
  if(request_status && request_status != status)
    next

  request_time = matches[4]
  if(mode == "quantil")
  {
    sorted_log_entries[count] = request_time
  }
  else
  {
    if(request_time > 0.1)
      count_bad += 1
    else if(request_time > 0.05)
      count_normal += 1
    else
      count_fine += 1
  }

  count += 1;
}
END{
  if(count > 0)
  {
    if(mode == "quantil")
    {
      elem_count = asort(sorted_log_entries)
      quantils_count = asort(quantils)

      for(i=1; i <= quantils_count; i++)
      {
        quantils_elem_count[i] = round(elem_count / 100 * quantils[i])
      }

      current_quantil = 0;
      request_time_summ = 0;

      for (i=1; i <= elem_count; i++)
      {
        if(i <= quantils_elem_count[current_quantil])
        {
          request_time_summ += sorted_log_entries[i]
        }
        else
        {
          average_request_time_for_quantil[current_quantil] = request_time_summ / i
          current_quantil++
        }
      }

      print "count:\t" elem_count
      print "time:\t" delta_time " (s)"

      for(i=1; i <= quantils_count; i++)
        printf "quantil_%.1f:\t%i (ms)\n", quantils[i], (average_request_time_for_quantil[i] * 1000)

    }
    else
      print now_date","count","count_fine","count_normal","count_bad
  }
}'
