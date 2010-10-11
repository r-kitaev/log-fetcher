gawk -v delta_time=$1 -v request_mask=$2 '
BEGIN{
  now_time = systime()
  now_date = strftime("%Y%m%d%H%M", now_time)
  begin_time = now_time - delta_time
  count = 0

  less_500ms = 0
  between_500ms_1000ms = 0
  greater_1000ms = 0
}
{
  log_time = $5

  if(log_time >= begin_time)
  {
    split($12, url, "?");

    is_ids = match(url[1], /\/(([0-9]+)(,|))+/)
    if(is_ids)
      gsub(/\/(([0-9]+)(,|))+/, "/IDS", url[1]);

    is_params = match(url[1], /\/([0-9a-zA-Z]+),(([0-9a-zA-Z]+)(,|))+/)
    if(is_params && !is_ids)
      gsub(/\/([0-9a-zA-Z]+),(([0-9a-zA-Z]+)(,|))+/, "/PARAMS", url[1]);

    current_url = url[1]
    status = $11

    current_request = substr(status""current_url, 2)
    if(current_request == request_mask)
    {
      count += 1;

      if($4 > 1)
        greater_1000ms += 1
      else if($4 > 0.5)
        between_500ms_1000ms += 1
      else
        less_500ms += 1
    }
  }
}
END{
  if(count > 0)
  {
    # print "count:"count" less_500ms:"less_500ms" between_500ms_1000ms:"between_500ms_1000ms" greater_1000ms:"greater_1000ms;
    print now_date","count","less_500ms","between_500ms_1000ms","greater_1000ms
  }
}'
