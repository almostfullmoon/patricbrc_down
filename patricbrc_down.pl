#! /usr/bin/perl
############################################################
#      Copyright (C) Hangzhou
#      作    者: 葛文龙
#      通讯邮件: gwl9505@163.com
#      脚本名称: patricbrc_down.pl
#      版    本: 1.0
#      创建日期: 2021年12月29日
############################################################
use v5.16;
use POSIX qw(strftime);
use List::MoreUtils ':all';
use FindBin qw($Bin);
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
use Date::Calc qw/Delta_Days/;
use Getopt::Long;
use vars qw($in_list $out_file $help $format);
GetOptions(
	"i:s" => \$in_list,
	"o:s" => \$out_file,
	"f:s" => \$format,
	"h" => \$help
);
&HELP if ($help);
if(!-s $in_list){die "ID列表文件 $in_list 不存在，检查-i参数\n";}
my $ok="fna\tfaa\tffn\tfrn\tgff\tfeatures.tab\tpathway.tab\tspgene.tab\tsubsystem.tab";
$format||="fna";
if($ok!~/\b$format\b/){die "-f参数所输入的格式不支持\n";}

$out_file||="patricbrc_down";
if(!-e $out_file){`mkdir $out_file`;}
sub HELP{
	say STDOUT "\n此脚本功能为下载patricbrc数据库";
	say STDOUT "用法: $0 -i (需要下载的基因id列表)\n";
	say STDOUT "\t-i : 基因id列表";
	say STDOUT "\t-o : 输出文件夹，默认为patricbrc_down\n";
	say STDOUT "\t-f : 下载的文件格式，默认fna，支持下列格式,输入方式如：-f ffn 或者 -f pathway.tab
		fna\t\tFASTA 重叠群序列
		faa\t\tFASTA 蛋白质序列文件
		ffn\t\t基因组特征的 FASTA 核苷酸序列，即基因、RNA 和其他杂项特征
		frn\t\tRNA 的 FASTA 核苷酸序列
		gff\t\tGFF 文件格式的基因组注释
		features.tab\t以制表符分隔格式的所有基因组特征和相关信息
		pathway.tab \t以制表符分隔格式的代谢途径分配
		spgene.tab  \t以制表符分隔格式的特殊基因分配(即 AMR 基因、毒力因子、必需基因等)
		subsystem.tab\t制表符分隔格式的子系统分配";
	say "\t","-"x20;
	exit;
}

#路径定义，文件检查
my $genome_summary=$Bin."/genome_summary";
my $genome_summary_time=strftime("%Y-%m-%d",localtime( (stat $genome_summary)[10]));
my $now_time=strftime("%Y-%m-%d", localtime);
my @ges_time=split(/-/,$genome_summary_time);
my @now_time=split(/-/,$now_time);
my $days = Delta_Days($ges_time[0],$ges_time[1],$ges_time[2],$now_time[0],$now_time[1],$now_time[2]);
if(-s "down_log.txt"){`rm down_log.txt`;}
if((!-s $genome_summary) or ($days > 15)){
	say "genome_summary 不存在或者更新时间为15天之前，重新下载";
	`rm $genome_summary`;
	`wget -P $Bin ftp://ftp.patricbrc.org/RELEASE_NOTES/genome_summary > down_log.txt 2>&1`;
}

open SU,'<',$genome_summary;
my %ges;
<SU>;
while(<SU>){
	my @id=split(/\t/,$_);
	$ges{$id[0]}=1;
}
close SU;
open IN,'<',$in_list;
my (@in_id,@un_in_id);
while(<IN>){
	chomp;
	push(@in_id,$_);
	@un_in_id=uniq(@in_id);
}
close IN;

for(@un_in_id){
	my $ca=$_;
	if(defined $ges{$ca}){
		my $ca_f=$_.".".$format;
		my $name;
		if($ca=~/(.*?)\./){$name=$Bin."/".$1;}
		my $gene_file=$name."/".$ca_f;
		if(!-s $gene_file){
			say "开始下载$ca_f，下载日志写入down_log.txt";
			`wget -P $name -t 0 ftp://ftp.patricbrc.org/genomes/$ca/$ca_f > down_log.txt 2>&1`;
		}
		`cp $gene_file $out_file`;
	}else{say BOLD RED "$ca 在genome_summary文件中不存在，已略过";}
}

say "\n运行结束，所有序列已存放至$out_file";
