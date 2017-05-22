# Get a list of files created within the last hour
Get-ChildItem -Recurse -ErrorAction SilentlyContinue -Filter *  | ? {$_.CreationTime -gt (get-date).AddHours(-1)}

# Get a list of files modified within the last hour
Get-ChildItem -Recurse -ErrorAction SilentlyContinue -Filter *  | ? {$_.LastWriteTime -gt (get-date).AddHours(-1)}

Get-ChildItem -Recurse -ErrorAction SilentlyContinue -Filter *  | ? {$_.LastAccessTime -gt (get-date).AddHours(-1)}


