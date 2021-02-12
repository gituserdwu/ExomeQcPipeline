#!/DCEG/Resources/Tools/perl/5.18.0/bin/perl -w

use strict;
use warnings;
use Getopt::Long;

my $fil_cscore = 0;

GetOptions(
  "cscore" => \$fil_cscore,
);




die("Usage: $0 inputVCF output\n") if(@ARGV != 2);

my $inputVCF = $ARGV[0];
#my $filetrField = $ARGV[1];
my $output = $ARGV[1];

my $num_processed = vcf_base_change_counter($inputVCF,$output);

print("Total line processed: $num_processed\n");

sub vcf_base_change_counter {
 my ($file, $outfile)  = @_;
 my $operator = "";
 my $info = "";
 my $value = "";

 my @A2C = ();
 my @A2G = ();
 my @A2T = ();
 my @C2A = ();
 my @C2G = ();
 my @C2T = ();
 my @G2A = ();
 my @G2C = ();
 my @G2T = ();
 my @T2A = ();
 my @T2C = ();
 my @T2G = ();
 my @sample_ID = ();
 my $counter = 0;
# $A2G[0][3] = 9;
# $A2G[1][3] = 79;

# print "Test: $A2G[0][3]\t$A2G[0][2]\t$A2G[0][0]\t$A2G[0][1]\t$A2G[1][3]\n"; exit;
=head
 if($field =~ /^\s*([^<>=!\s]+)\s*([><=!]+)\s*([+-]?\d*\.?\d+)\s*$/) { #Doesn't handle scientfic annotation this time.
   if($2 eq "=" || $2 eq "==" || $2 eq ">" || $2 eq "<" || $2 eq ">=" || $2 eq "<=" || $2 eq "!=") {
     $operator = $2;
     $operator = "==" if($2 eq "=");
   } else { die("Error: unrecognized operator $2 $!\n");}
   $info = $1;
   $value = $3;
 } else {
   die("Error: unrecognized numeric filter option $field $!\n");
 }
=cut

 open(my $FH, "<$file") || die("Error: can't open input $file $!\n");
 open(my $OUT, ">$outfile") || die("Error: can't open output $outfile $!\n");

 while(<$FH>) {
   
   $counter++;
   print("Lines processed: $counter.\n") if($counter%10000 == 0);

   if(/^##/) { #Skip the meta header.
     #print($OUT $_);
     next;
   }
   chomp;

   my @vcf_column = split(/\t/, $_);

   if($vcf_column[0] =~ /^#CHROM$/i && $vcf_column[1] =~ /^POS$/i &&  $vcf_column[2] =~ /^ID$/i && $vcf_column[3] =~ /^REF$/i && $vcf_column[4] =~ /^ALT$/i && $vcf_column[5] =~ /^QUAL$/i && $vcf_column[6] =~ /^FILTER$/i && $vcf_column[7] =~ /^INFO$/i && $vcf_column[8] =~ /^FORMAT$/i) {
      @sample_ID = @vcf_column;
#   print("Here: $vcf_column[10]\n"); 
      splice(@sample_ID, 0, 9);
#      print("$sample_ID[0]\t$sample_ID[1]\n");
      next;
   }
#  print("$sample_ID[0]\t$sample_ID[1]\t".scalar(@sample_ID)."\n");
#  print("EXIT\n"); exit;

  # if($vcf_column[0] !~ /^chr/i || $vcf_column[1] !~ /\d+/ ||  $vcf_column[3] !~ /[AGTC]+/i || $vcf_column[4] !~ /[AGTC]+/i || $vcf_column[5] !~ /[+-]?\d*\.?\d+/) { #Sanity check
    if($vcf_column[1] !~ /\d+/ ||  $vcf_column[3] !~ /[AGTC]+/i || $vcf_column[4] !~ /[AGTC]+/i || $vcf_column[5] !~ /[+-]?\d*\.?\d+/) { #Sanity check
     print("Warning: the line record deons't appear to be in a valid format: $_  Skipping. $!\n");
     next;
   }


#   print("QUAL: $vcf_column[5]\n");

   my $bin_num = get_Bin_Num($vcf_column[5]);
   next if($bin_num == -1); # Skip unqualified variant line  
 #  next if($fil_cscore && $vcf_column[6] =~ /CScoreFilter/);   
   next if($fil_cscore && $vcf_column[6] =~ /1/); #change CScoreFiler to majority voting

   my $total_sample_count = scalar(@vcf_column) - 9;
 #  print("Total sample count: $total_sample_count\n");
   die("Error: Incorrect sample number $total_sample_count.\n") if($total_sample_count <= 0); 


   for my $sample_index (9 .. $#vcf_column) {
     my $array_index = $sample_index - 9;
     # Need add GQ check later.     
     my @genome_type = split(/:/,$vcf_column[$sample_index]);
     next if($genome_type[0] ne "0/1" && $genome_type[0] ne "1/1" && $genome_type[0] ne "0|1" && $genome_type[0] ne "1|1");
     if($vcf_column[3] eq "A") {
        if($vcf_column[4] eq "C") { 
          if(!defined $A2C[$array_index][$bin_num] ) {
            $A2C[$array_index][$bin_num] = 1;
          } else { $A2C[$array_index][$bin_num]++; }
        } elsif($vcf_column[4] eq "G") {
          if(!defined $A2G[$array_index][$bin_num] ) {
            $A2G[$array_index][$bin_num] = 1;
          } else { $A2G[$array_index][$bin_num]++; }
        } elsif($vcf_column[4] eq "T") {
          if(!defined $A2T[$array_index][$bin_num] ) {
            $A2T[$array_index][$bin_num] = 1;
          } else { $A2T[$array_index][$bin_num]++; }
        }

     } elsif ($vcf_column[3] eq "C") {
        if($vcf_column[4] eq "A") {
          if(!defined $C2A[$array_index][$bin_num] ) {
            $C2A[$array_index][$bin_num] = 1;
          } else { $C2A[$array_index][$bin_num]++; }
        } elsif($vcf_column[4] eq "G") {
          if(!defined $C2G[$array_index][$bin_num] ) {
            $C2G[$array_index][$bin_num] = 1;
          } else { $C2G[$array_index][$bin_num]++; }
        } elsif($vcf_column[4] eq "T") {
          if(!defined $C2T[$array_index][$bin_num] ) {
            $C2T[$array_index][$bin_num] = 1;
          } else { $C2T[$array_index][$bin_num]++; }
        }
       
     } elsif ($vcf_column[3] eq "G") {
        if($vcf_column[4] eq "A") {
          if(!defined $G2A[$array_index][$bin_num] ) {
            $G2A[$array_index][$bin_num] = 1;
          } else { $G2A[$array_index][$bin_num]++; }
        } elsif($vcf_column[4] eq "C") {
          if(!defined $G2C[$array_index][$bin_num] ) {
            $G2C[$array_index][$bin_num] = 1;
          } else { $G2C[$array_index][$bin_num]++; }
        } elsif($vcf_column[4] eq "T") {
          if(!defined $G2T[$array_index][$bin_num] ) {
            $G2T[$array_index][$bin_num] = 1;
          } else { $G2T[$array_index][$bin_num]++; }
        }

     } elsif ($vcf_column[3] eq "T") {
        if($vcf_column[4] eq "A") {
          if(!defined $T2A[$array_index][$bin_num] ) {
            $T2A[$array_index][$bin_num] = 1;
          } else { $T2A[$array_index][$bin_num]++; }
        } elsif($vcf_column[4] eq "C") {
          if(!defined $T2C[$array_index][$bin_num] ) {
            $T2C[$array_index][$bin_num] = 1;
          } else { $T2C[$array_index][$bin_num]++; }
        } elsif($vcf_column[4] eq "G") {
          if(!defined $T2G[$array_index][$bin_num] ) {
            $T2G[$array_index][$bin_num] = 1;
          } else { $T2G[$array_index][$bin_num]++; }
        }

     } else {;}

   } 



 #  my $currentLine = $_;
 #  my @infoField = split(/\;/, $vcf_column[7]);

 #  foreach(@infoField) {
 #    if($_ =~ /^\s*(\S*)\s*=\s*([+-]?\d*\.?\d+)\s*$/) { #Doesn't handle scientfic annotation this time.
 #      if($1 eq $info && eval($2.$operator.$value)) {
         #print "$1,$2\n";
 #        print($OUT "$currentLine\n");
 #      }
 #    }
 #  }
 }

 for(my $in=0; $in<=$#sample_ID; $in++) {
   print($OUT "$sample_ID[$in]\tA>C");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $A2C[$in][$bin]) {
       print($OUT "\t$A2C[$in][$bin]");
     } else { print($OUT "\t0"); } 
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tA>G");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $A2G[$in][$bin]) {
       print($OUT "\t$A2G[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tA>T");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $A2T[$in][$bin]) {
       print($OUT "\t$A2T[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tC>A");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $C2A[$in][$bin]) {
       print($OUT "\t$C2A[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tC>G");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $C2G[$in][$bin]) {
       print($OUT "\t$C2G[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tC>T");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $C2T[$in][$bin]) {
       print($OUT "\t$C2T[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tG>A");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $G2A[$in][$bin]) {
       print($OUT "\t$G2A[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tG>C");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $G2C[$in][$bin]) {
       print($OUT "\t$G2C[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tG>T");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $G2T[$in][$bin]) {
       print($OUT "\t$G2T[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tT>A");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $T2A[$in][$bin]) {
       print($OUT "\t$T2A[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tT>C");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $T2C[$in][$bin]) {
       print($OUT "\t$T2C[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");

   print($OUT "$sample_ID[$in]\tT>G");
   for(my $bin=0; $bin<=10; $bin++) {
     if(defined $T2G[$in][$bin]) {
       print($OUT "\t$T2G[$in][$bin]");
     } else { print($OUT "\t0"); }
   }
   print($OUT "\n");


 } 

 close($FH);
 close($OUT);
 return $counter;
}

sub get_Bin_Num {

 my ($variant_score)  = @_;

 return 0 if($variant_score >= 0 && $variant_score <= 90);
 return 1 if($variant_score > 90 && $variant_score <= 400); 
 return 2 if($variant_score > 400 && $variant_score <= 2400);
 return 3 if($variant_score > 2400 && $variant_score <= 6000);
 return 4 if($variant_score > 6000 && $variant_score <= 12000);
 return 5 if($variant_score > 12000 && $variant_score <= 20000);
 return 6 if($variant_score > 20000 && $variant_score <= 36000);
 return 7 if($variant_score > 36000 && $variant_score <= 60000);
 return 8 if($variant_score > 60000 && $variant_score <= 100000);
 return 9 if($variant_score > 100000 && $variant_score <= 1600000);
 return 10 if($variant_score > 1600000);
 return -1;

}
