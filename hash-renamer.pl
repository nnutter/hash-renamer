#!/usr/bin/env perl

use Modern::Perl '2014';

use Crypt::Digest::SHA1 qw(sha1_file_hex);
use File::Basename qw(fileparse);
use File::Path qw(make_path);

require File::Find::Rule;
require File::Spec;
require Image::ExifTool;

my $src = shift @ARGV
    or die 'must specify source directory';

my $dst = shift @ARGV
    or die 'must specify destination directory';

my $extensions = qr/\.(jpg|jpeg|bmp|avi|mov|mp4|png|tif|mpg|m4v)/i;

my $rule = File::Find::Rule->file
                           ->name($extensions)
                           ->start($src);

my $date_format = '%Y-%m-%dT%H:%M:%S%z';
my $exiftool = Image::ExifTool->new();
$exiftool->Options(DateFormat => $date_format);

while ( defined ( my $path = $rule->match ) ) {
    my $info = $exiftool->ImageInfo($path);
    my $sha1 = sha1_file_hex($path);
    my $prefix = substr($sha1, 0, 2);
    my $suffix = substr($sha1, 2);
    my $extension = normalize_extension((fileparse($path, $extensions))[2]);
    my $filename = join('', $suffix, $extension);
    my $new_dir = File::Spec->join(
        $dst,
        $prefix,
    );
    my $new_name = File::Spec->join(
        $new_dir,
        $filename,
    );

    if ( -f $new_name ) {
        if ( -s $new_name != -s $path ) {
            printf "%s != %s\n", $path, $new_name;
        }
        else {
            unlink $path;
        }
        next;
    }

    say $new_name;
    make_path $new_dir;
    rename $path, $new_name;
}

sub normalize_extension {
    my $input = shift;
    my $output = lc($input);
    my %norm = (
        '.jpeg' => '.jpg',
    );
    if ($norm{$output}) {
        $output = $norm{$output};
    }
    return $output;
}
