#!/usr/bin/perl -w

use strict;
use Math::Round;

sub slizik {
	my ($h, $yaw, $infile, $outfile) = @_;

	# Generic options
	my $quality = 95;
	my $format = "JPEG c:$quality";
	my $ptofile = "brno.pto";

	# Pitch and roll
	my $pitch = 90; # city centre: equator/poles?
	my $roll  = 0;  # tilt

	# Calculate integral bounds
	my ($centerx, $dx) = (1.7207, 0.0900);
	my ($centery, $dy) = (0.8640, 0.5000);

	my $imgw  = round(3.448 * $h);
	my $imgh  = round(1.724 * $h);
	my $left  = round(($centerx-$dx) * $h);
	my $right = round(($centerx+$dx) * $h);
	my $top   = round(($centery-$dy) * $h);
	my $bot   = round(($centery+$dy) * $h);

	print "$outfile: ";
	print "PTO ";
	open my $F, ">$ptofile";
	print $F "p f6 w$imgw h$imgh v179 E0 R0 S$left,$right,$top,$bot n\"$format r:CROP\"\n";
	print $F "m g1 i0 f0 m2 p0.00784314\n";
	print $F "i w8000 h8000 f10 v292.152297783717 Ra0 Rb0 Rc0 Rd0 Re0 Eev0 Er1 Eb1 r$roll p$pitch";
	print $F "  y$yaw TrX0 TrY0 TrZ0 j0 a0 b0 c0 d0 e0 g0 t0 Va1 Vb0 Vc0 Vd0 Vx0 Vy0 Vm5 n\"$infile\"\n";
	print $F "v r0\nv p0\nv y0\nv\n";
	close $F;

	print "NONA ";
	system("nona -o $outfile $ptofile") == 0 or die "Could not remap image";
	print "POSTPROC ";
	system("mogrify "
		. "-quality $quality "
		. "-crop "
			. ($right-$left)."x".($bot-$top)
			. "+".$left."+".$top." "
		. "-fill '#2c5573' -fuzz 5% -opaque black "
		. "$outfile"
	) == 0 or die "Could not postprocess image.";
	
	print "- OK\n";
}

my $count = 12;
for my $i (0..$count-1)
{
	slizik(400, $i*360.0/$count, 'brno8000.jpg', "sliz-$i.jpg");
}



