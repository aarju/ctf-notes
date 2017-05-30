function grep {
  $input | out-string -stream | select-string $args
}
