use v6;

grammar IniFile {
    token ws      { \h* }
    token key     { \w+ }
    token value   { <!before \s> <-[\n;]>+ <!after \s> }
    rule  pair    { <key> '='  <value> \n+ }
    token header  { '[' ( <-[ \[ \] \n ]>+ ) ']' \n+ }
    token comment { ';' \N*\n+  }
    token block   { [<pair> | <comment>]* }
    token section { <header> <block> }
    token TOP     { <block> <section>* }
}

class IniFile::Actions {
    method key($/)     { make $/.Str }
    method value($/)   { make $/.Str }
    method header($/)  { make $/[0].Str }
    method pair($/)    { make $<key>.made => $<value>.made }
    method block($/)   { make $<pair>.map({ .made }).hash }
    method section($/) { make $<header>.made => $<block>.made }
    method TOP($/)     {
        make {
            _ => $<block>.made,
            $<section>.map: { .made },
        }
    }
}

sub parse-ini(Str $input) {
    my $m = IniFile.parse($input, :actions(IniFile::Actions));
    unless $m {
        die "The input is not a valid INI file.";
    }

    return $m.made
}

my $ini = q:to/EOI/;
key1=value2

[section1]
key2=value2
key3 = with spaces
; comment lines start with a semicolon, and are
; ignored by the parser

[section2]
more=stuff
EOI

say parse-ini($ini).perl;
