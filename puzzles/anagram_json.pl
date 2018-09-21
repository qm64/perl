#Anagram engine
#
#Given:
#    Word hash
#        key: valid word
#        val: sorted anagram
#    Anagram hash
#        key: sorted anagram
#        val: hash
#                key: valid word
#                val: 1
#                
#Target:
#    Given a target word or phrase,
#    Find all the words or phrases that anagram to the target
#           
#Method:
#    Use regex of sorted anagram against the target anagram.
#    On match, reduce the target by the match
#             
#Do:
#    # find anagram "vectors" that sum to the target vector
#    Create an anagram regex hash
#        key: sorted anagram
#        val: equivalent regex. That is, 'aaaffq' => 'a{3}.*?f{2}.*?q{1}'
#        
#How to match efficiently?
#    Longest to shortest? (Ultimately, must be able to generate them all, to any depth.)
#    Create one large regex from all pieces, with names given by the sorted anagram (!!)
#        This allows for named captures?
#            Named captures can't start with number, or include hyphens.
#    Compute a minimum alphabet for each dict word, and the target.
#       Only include dict words that are a subset of the target alphabet.
#       Only include dict words shorter or same length as target.
#    
#    Construct match like so:
#       $target =~ s/^(<s_k_i_p_1>.*?)(<word_a>a{0,3})(<s_k_i_p_2>.*?)(<word_b>b{0,3})(<s_k_i_p_3>.*?)...$/${s_k_i_p_1}${s_k_i_p_2}.../e;
#       Check that the new $target is shorter, else there was no interesting match.
#    For each word that matched
#       remove it from the candidate list
#       recompute the regex
#   Loop until no matches, and target is consumed completely.
#   For each word that matches, remove it from the candidate list and start again.
#       ? Might need to match only one word at a time, and work recursively, backtracking on full anagram failure.