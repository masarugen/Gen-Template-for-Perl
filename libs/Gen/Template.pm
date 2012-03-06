package Gen::Template;
use Gen;

my (%tconfig, $configs);
my ($bss, $bse, $bes, $bee, $cs, $ce, $cbs, $cbe, $ds, $de, $dsn, $den);
my ($lss, $lse, $les, $lee, $iss, $ise, $ies, $iee);
my ($ess, $ese, $ees, $eee, $eol);
my ($mss, $mse, $mes, $mee);

sub new
{
  my ($class) = @_;
  # template setting
  %tconfig = (
    'mark_comment_start' => '{{',
    'mark_comment_end' => '}}',
    'mark_start' => '<!--',
    'mark_end' => '-->',
    'block_start' => '', 
    'block_end' => '/',
    'main_block' => '%',   # <!--%main%--> <!--/%main%/-->
    'mark_comment' => '#', # <!--#--> <!--/#/-->
    'mark_data' => '=',    # <!--=a=/-->
    'mark_loop' => '~',    # <!--~a~--> <!--/~a~/-->
    'mark_if' => '|',      # <!--|calc|--> <!--/|calc|/-->
    'mark_else' => '!',    # <!--!calc!/-->
  );
  # configs
  $configs  = "\Q$tconfig{'mark_comment'}\E";
  $configs .= '|'."\Q$tconfig{'mark_data'}\E";
  $configs .= '|'."\Q$tconfig{'mark_loop'}\E";
  $configs .= '|'."\Q$tconfig{'mark_if'}\E";
  $configs .= '|'."\Q$tconfig{'mark_else'}\E";
  # block
  $bss = "\Q$tconfig{'mark_start'}$tconfig{'block_start'}\E";
  $bse = "\Q$tconfig{'block_start'}$tconfig{'mark_end'}\E";
  $bes = "\Q$tconfig{'mark_start'}$tconfig{'block_end'}\E";
  $bee = "\Q$tconfig{'block_end'}$tconfig{'mark_end'}\E";
  # mian_block
  $mss = $bss."\Q$tconfig{'main_block'}\E";
  $mse = "\Q$tconfig{'main_block'}\E".$bse;
  $mes = $bes."\Q$tconfig{'main_block'}\E";
  $mee = "\Q$tconfig{'main_block'}\E".$bee;
  # comment
  $cs = "\Q$tconfig{'mark_comment_start'}\E";
  $ce = "\Q$tconfig{'mark_comment_end'}\E";
  $cbs = $bss."\Q$tconfig{'mark_comment'}\E".$bse;
  $cbe = $bes."\Q$tconfig{'mark_comment'}\E".$bee;
  # data
  $ds  = $bss."\Q$tconfig{'mark_data'}\E";
  $de  = "\Q$tconfig{'mark_data'}\E".$bee;
  $dsn = "$tconfig{'mark_start'}$tconfig{'block_start'}$tconfig{'mark_data'}";
  $den = "$tconfig{'mark_data'}$tconfig{'block_end'}$tconfig{'mark_end'}";
  # loop
  $lss = $bss."\Q$tconfig{'mark_loop'}\E";
  $lse = "\Q$tconfig{'mark_loop'}\E".$bse;
  $les = $bes."\Q$tconfig{'mark_loop'}\E";
  $lee = "\Q$tconfig{'mark_loop'}\E".$bee;
  # if
  $iss = $bss."\Q$tconfig{'mark_if'}\E";
  $ise = "\Q$tconfig{'mark_if'}\E".$bse;
  $ies = $bes."\Q$tconfig{'mark_if'}\E";
  $iee = "\Q$tconfig{'mark_if'}\E".$bee;
  # else
  $ess = $bss."\Q$tconfig{'mark_else'}\E";
  $ese = "\Q$tconfig{'mark_else'}\E".$bse;
  $ees = $bes."\Q$tconfig{'mark_else'}\E";
  $eee = "\Q$tconfig{'mark_else'}\E".$bee;
  $eol = "(?:\x0D\x0A|\x0D|\x0A)?";
  bless {}, $class;
}

# -- ビューの作成 --
sub create_view
{
  my ($self, $template, $data, $page) = @_;
  $template = $self->remove_comment($template);
  $template = $self->replace_block($template, $data, $page);
  $template = $self->replace_data($template, $data);
  return $template;
}

# -- Templateファイルのロード --
sub load_template
{
  my ($self, $path, $in_enc) = @_;
  my ($text, $fp);
  $in_enc = 'utf8' unless defined($in_enc);
  open $fp, " < $path " or die("File Not Open:$!\n");
  while (<$fp>) {
    $_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
    chomp;
    Encode::from_to($_, $in_enc, 'utf8');
    $_ = Encode::decode_utf8($_);
    $text .= "$_\n";
  }
  close $fp;
  return $text;
}

# -- エンコードの変更 --
sub convert_encode
{
  my ($self, $text, $out_enc) = @_;
  $text = Encode::encode_utf8($text);
  Encode::from_to($text, 'utf8', $out_enc);
  return $text;
}

# -- メインブロックの切り出し --
sub main_block
{
  my ($self, $template, $blockname) = @_;
  $template =~ m/$mss$blockname$mse$eol(.*)$mes$blockname$mee$eol/sgmo;
  if (defined($1)) {
    $template = $1;
  } else {
    $template =~ m/(.*)$mes$blockname$mee$eol/sgmo;
    if (defined($1)) {
      $template = $1;
    } else {
      $template =~ m/$mss$blockname$mse$eol(.*)/sgmo;
      if (defined($1)) {
        $template = $1;
      }
    }
  }
  return $template;
}

# -- コメントの削除 --
sub remove_comment
{
  my ($self, $template) = @_;
  $template =~ s/$cs.*?$ce//sgmo;
  $template =~ s/$cbs.*?$cbe$eol//sgmo;
  return $template;
}

# -- ブロック要素の置換 --
sub replace_block
{
  my ($self, $template, $data, $class) = @_;
  my (@matches_contents, @matches_kind, @matches_name, @matches_template);
  while ($template =~ m/$bss($configs)(.*?)\1$bse$eol(.*?)$bes\1\2\1$bee$eol/sgmo) {
    push (@matches_contents, 1);
    push (@matches_kind, $1);
    push (@matches_name, $2);
    push (@matches_template, $3);
  }
  my %subdata = %$data;
  my ($temp, $replace);
  for (my $i=0 ; $i <= $#matches_contents ; $i++) {
    $temp = '';
    $replace = 0;
    if ($matches_kind[$i] eq $tconfig{'mark_loop'}) {
      $temp = $self->replace_loop($matches_template[$i], $subdata{$matches_name[$i]}, $class);
      $replace = 1;
    } elsif ($matches_kind[$i] eq $tconfig{'mark_if'}) {
      $temp = $self->replace_condition($matches_template[$i], $matches_name[$i], $data, $class, 1);
      $replace = 1;
    } elsif ($matches_kind[$i] eq $tconfig{'mark_else'}) {
      $temp = $self->replace_condition($matches_template[$i], $matches_name[$i], $data, $class, 0);
      $replace = 1;
    }
    if ($replace) {
      $template =~ s/$bss(\Q$matches_kind[$i]\E)(\Q$matches_name[$i]\E)\1$bse$eol(?:.*?)$bes\1\2\1$bee$eol/$temp/sm;
    }
  }
  return $template;
}

# -- ループ部分の置換 --
sub replace_loop
{
  my ($self, $template, $loop_data, $class) = @_;
  my $ret_template = '';
  my $temp;
  foreach my $data (@$loop_data) {
    $temp = '';
    $temp = $self->replace_block($template, $data, $class);
    $temp = $self->replace_data($temp, $data);
    $ret_template .= $temp;
  }
  return $ret_template;
}

# -- 条件文の置換 --
sub replace_condition
{
  my ($self, $template, $name, $data, $class, $result) =@_;
  my $method = 'if_'.$name;
  my $subname = ref($class)."::".$method;
  unless (exists(&$subname)) {
    $method = 'if_pagedefault';
    $subname = ref($class)."::".$method;
    Gen::confess("Undefined Page Condition : $name") unless (exists(&$subname));
  }
  my $ret = $class->$method($data);
  if ($ret eq $result || $ret == $result) {
    $template = $self->replace_block($template, $data, $class);
    $template = $self->replace_data($template, $data);
  } else {
    $template =~ s/.*//smo;
  }
  return $template;
}

sub replace_data {
  my ($self, $template, $data) = @_;
  my (@matches_contents, @matches_name);
  while ($template =~ m/$ds(.*?)$de/sgmo) {
    push (@matches_contents, "$dsn$1$den");
    push (@matches_name, $1);
  }
  my %subdata = %$data;
  for (my $i=0 ; $i <= $#matches_contents ; $i++) {

    if (defined($subdata{$matches_name[$i]})) {
      $template =~ s/\Q$matches_contents[$i]\E/$subdata{$matches_name[$i]}/sm;
    } else {
      $template =~ s/\Q$matches_contents[$i]\E//sm;
    }
  }
  return $template;
}

1;
