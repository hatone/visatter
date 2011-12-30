use strict;
use warnings;
use utf8;

use HTTP::Cookies;
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON::XS;
use Data::Dumper;
use Net::Twitter;
use Encode;

#クレジットカードの情報
my $card_number = "hogehoge";
my $security_code = "hogehoge";
my $formdata = {
    'CardNumber'    => $card_number,
    'SecurityCode'   => $security_code,
    'Last4OfPhone'    => 'hogehoge',
};

#twitterのauth情報
my $consumer_key = 'hoge';
my $consumer_key_secret = 'hoge';
my $access_token = 'hoge';
my $access_token_secret ='hoge';

my $ua = new LWP::UserAgent;
#fileopen(read)
my $file = 'visatter';
open(LOG, "<$file") or die "$!";
my $line = <LOG>;
close(LOG);
my $response = $ua->request(
    HTTP::Request::Common::POST(
        'https://mygift.giftcardmall.com/MyCard/',
        $formdata,
    )
);

# cookie_jar の生成、
# それから UA に cookie （セッション情報）をセットする。
my $cookie_jar = HTTP::Cookies->new( autosave => 1 );
 $cookie_jar->extract_cookies( $response );

$ua->cookie_jar( $cookie_jar );

unless( $cookie_jar->as_string ){
    print "login failed.";
    exit;
}

#return $ua;
print "login ok\n";
my $res = $ua->post(
    "https://mygift.giftcardmall.com/TransactionHistory/_Index",
    {
        #none
    },
    "X-Requested-With" => "XMLHttpRequest"
);

my $res_json = decode_json($res->content);

#print $res_json->{data}[0]->{Description};
my $min_balance = $line;
foreach my $transaction (@{$res_json->{data}}){
    my $d = $transaction->{POSDate};
    $d =~ s/T/-/;
    $d =~ s/\./-/;
    my @sd = split(/-/,$d);

    my $res_s = "はとねが ".$transaction->{Description}.", ".$transaction->{MerchantCity}." ".$transaction->{MerchantState}." で ".$transaction->{Amount}." を".$transaction->{Type}."しました。"." #はとったー\n";

    $res_s =~ s/<.*>-//;
    $res_s =~ s/<\/.*>//;
    print encode('utf-8', $res_s);
   
    my $balance = $transaction->{Balance} || 0;
    $balance =~ s/\$//;
    if( (int($line) > int($balance)))
    {

        my $nt = Net::Twitter ->new (
                    traits => ['API::REST' ,'OAuth'],
                    consumer_key => $consumer_key,
                    consumer_secret => $consumer_key_secret,
                                                );
        $nt -> access_token($access_token);
        $nt -> access_token_secret($access_token_secret);
        if(int($balance) < int($min_balance)){
            $min_balance = $balance;
        }
        print "tweet!\n";
       
        my $res = $nt->update({status => $res_s });
   
    }

}
open(LOG, ">$file") or die "$!";
print LOG $min_balance;
close(LOG);
 
print "\n";
