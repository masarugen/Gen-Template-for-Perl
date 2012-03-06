#!/usr/bin/perl

use lib qw(. ./libs);
use Gen::Template;

# 条件分岐用クラス
package Page;
sub new
{
  my $class = shift;
  bless {}, $class;
}

sub if_check
{
   my ($self, $data) = @_;
   my $ret = 0;
   if ($data->{'check'} == 1) {
     $ret = 1;
   }
   return $ret;
}

package main;
use utf8;

# 出力データの生成
my %data = (
  'data1' => 'データ',
  'loop1' => [
    {
       'name' => '１つ目です',
       'check' => 1,
    },
    {
       'name' => '２つ目です',
       'check' => 0,
    }
  ]
);

# テンプレートファイルの読み込み 
my $template = Gen::Template->new();
my $text = $template->load_template('./test_temp.html', 'utf8');
my $page = Page->new();
$text = $template->create_view($text, \%data, $page);

print "Content-type: text/html; charset=UTF-8\n\n";
$text = $template->convert_encode($text, 'utf8');
print $text;
