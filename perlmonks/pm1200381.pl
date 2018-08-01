$_ = '"' . ('x\"' x 100000) . '"';
#print "NOT MATCHED!\n" unless
#  /^ " (?: [^"\\]+ | (?: \\. )+ )*+ " /x;
#
#print "NOT MATCHED!\n" unless
#  /^ " (?: [^"\\]++ | (?: \\. )++ )*+ " /x ;

print "NOT MATCHED!\n" unless
#  /^ " (?: [^"\\]+ | (?: \\. )+ )*+ " /x ;

  /^ " (?: [^"\\]+ | (?: \\. )+ )*+ " /x ;