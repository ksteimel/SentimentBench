using Test
include("../MutualInfo.jl")
ss = SubString

@testset "document processing" begin
  @testset "construction" begin
    @testset "default_args" begin
        default_obj = CountVectorizer()
        @test isa(default_obj,CountVectorizer)
        @test default_obj.input == "content"
        @test default_obj.decode_error == "Nothing"
        @test default_obj.strip_accents == false
        @test default_obj.lowercase == true
        @test default_obj.preprocessor == nothing
        @test default_obj.tokenizer == nothing
        @test default_obj.stop_words == nothing
        @test default_obj.token_pattern == nothing
        @test default_obj.ngram_range == (1,1)
        @test default_obj.analyzer == nothing
        @test default_obj.vocabulary == [""]
        @test default_obj.binary == true
        @test default_obj.dtype == nothing
    end
    @test_throws ErrorException CountVectorizer(input="files")
    filename_obj = CountVectorizer(input="filename")
    @test filename_obj.input == "filename"
    file_obj = CountVectorizer(input="file")
    @test file_obj.input == "file"
  end
  @testset "tokenization" begin
    function tokenize_function(input::String)
    """
    This is a simple routine that breaks a string up
    into a 1d array of SubStrings

    This is used simply for testing the function_tokenize method
    """
      delim = ' '
      substrings = SubString[] #declare array of substrings
      last_boundary = 1
      for char_I in eachindex(input)
        if input[char_I] == delim
          push!(substrings, input[last_boundary:char_I-1])
          last_boundary = char_I + 1
        end
        if char_I == length(input)
          push!(substrings, input[last_boundary:char_I])
        end
      end
      return substrings
    end
    default_vectorizer = CountVectorizer()
    sent = "Hey, this is a test sentence!"
    @test [ss("Hey,"),
          ss("this"),
          ss("is"),
          ss("a"),
          ss("test"),
          ss("sentence!")] == white_space_tokenize(default_vectorizer, sent)

    multi_sent = ["Hey, this is a test sentence!",
                "What do you think this will do?"]
    expected_result_with_punct = [[ss("Hey,"), ss("this"), ss("is"), ss("a"),
                                  ss("test"), ss("sentence!")],
                                  [ss("What"), ss("do"), ss("you"), ss("think"),
                                  ss("this"), ss("will"), ss("do?")]]
    @test expected_result_with_punct == white_space_tokenize(default_vectorizer,
                                                              multi_sent)
    tokenize_regex = r"[?!,\"\\;:.]?( |^)"
    regex_vectorizer = CountVectorizer(token_pattern=tokenize_regex)
    @test [[ss("Hey"),
            ss("this"),
            ss("is"),
            ss("a"),
            ss("test"),
            ss("sentence!")],
          [ss("What"),
            ss("do"),
            ss("you"),
            ss("think"),
            ss("this"),
            ss("will"),
            ss("do?")]] == regex_tokenize(regex_vectorizer, multi_sent)
    tokenize_regex = r"$"
    #This should produce empty strings in the function that will be filtered out
    regex_vectorizer = CountVectorizer(token_pattern = tokenize_regex)
    @test [[ss("Hey, this is a test sentence!")],
            [ss("What do you think this will do?")]] == regex_tokenize(regex_vectorizer,
                                                                        multi_sent)
    function_vectorizer = CountVectorizer(tokenizer=tokenize_function)
    @test expected_result_with_punct == function_tokenize(function_vectorizer,
                                                              multi_sent)
    multi_sent = ["Hey, this isn,t a test sentence!",
                  "What do you think this will do?"]
    preprocessing_target = ["hey , this isn , t a test sentence !",
                            "what do you think this will do ?"]
    @test eng_preprocessing(default_vectorizer, multi_sent, punct_expand=true) == preprocessing_target
    multi_sent = ["Hey this is a test:)",
                  "@dood What do you think this will do?",
                  "My number is 819-9283 and my email is ks@test.com"]
    tokenized_output = [[ss("Hey"),
                        ss("this"),
                        ss("is"),
                        ss("a"),
                        ss("test"),
                        ss(":)")],
                        [ss("@dood"),
                        ss("What"),
                        ss("do"),
                        ss("you"),
                        ss("think"),
                        ss("this"),
                        ss("will"),
                        ss("do"),
                        ss("?")],
                        [ss("My"),
                        ss("number"),
                        ss("is"),
                        ss("819-9283"),
                        ss("and"),
                        ss("my"),
                        ss("email"),
                        ss("is"),
                        ss("ks@test.com")]]
  @testset "tweet tokenize regexes" begin
    #These are the individual regular expressions that define a token in
    #tweet_tokenize
    emoticons = r"([<>]?[:;=8][\-o\*\']?[\)\]\(\[dDpP/\:\}\{@\|\\]|[\)\]\(\[dDpP/\:\}\{@\|\\][\-o\*\']?[:;=8][<>]?|<3)"
    @test match(emoticons, "hey what's up :)").match == ss(":)")
    @test match(emoticons, "uh >:-( why?").match == ss(">:-(")
    @test match(emoticons, "best show evar <3").match == ss("<3")
    url = r"(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+"
    @test match(url, "check this https://t.co/a23wwldl").match == ss("https://t.co/a23wwldl")
    @test match(url, "My website can be found at http://git.ksteimel.duckdns.org
          if you're interested").match == ss("http://git.ksteimel.duckdns.org")
    @test match(url, "google.com is boring").match == ss("google.com")
    phone_numbers = r"(\+?[01][ *\-.\)]*)?([\(]?\d{3}[ *\-.\)]*)?\d{3}[ *\-.\)]*\d{4}"
    @test match(phone_numbers, "Hey 949-8268 was my number").match == ss("949-8268")
    html_tags = r"<[^>\s]+>"
    @test match(html_tags, "Uh line breaks in html are<br>named after Brazil").match ==
            ss("<br>")
    asci_arrows = r"[\-]+>|<[\-]+"
    @test match(asci_arrows, "@dood23 <- this guy is hilarious").match == ss("<-")
    handles = r"@[\w_]+"
    sentence_with_handles = "@dood23 do you even lift"
    @test match(handles, sentence_with_handles).match == ss("@dood23")
    #handles are over matching some things so I want to check that too
    @test match(url, sentence_with_handles) == nothing
    @test match(asci_arrows, sentence_with_handles) == nothing
    @test match(emoticons, sentence_with_handles) == nothing
    @test match(phone_numbers, sentence_with_handles) == nothing
    @test match(html_tags, sentence_with_handles) == nothing
    hashtags = r"(?:\#+[\w_]+[\w\'_\-]*[\w_]+)"
    @test match(hashtags, "#nlp is better than #cl maybe?").match ==
            ss("#nlp")
    email_addresses = r"[\w.+-]+@[\w-]+\.(?:[\w-]\.?)+[\w-]"
    @test match(email_addresses, "halp plz email me at ksteimel@example.com").match ==
            ss("ksteimel@example.com")
    @test match(email_addresses, sentence_with_handles) == nothing
    # Words with apostrophes or dashes.
    words = r"(?:[^\W\d_](?:[^\W\d_]|['\-_])+[^\W\d_])"
    @test match(words, "cats are non-neutonian fluids").match == ss("cats")
    @test match(words, sentence_with_handles).match == ss("dood")
    # Numbers, including fractions, decimals.
    numbers = r"(?:[+\-]?\d+[,/.:-]\d+[+\-]?)"
    @test match(numbers, "1,984 was a book, and a Van Halen album").match == ss("1,984")
    @test match(numbers, sentence_with_handles) == nothing
    # Words without apostrophes or dashes.
    bare_words = r"(?:[\w_]+)"
    @test match(bare_words, ":) test things").match == ss("test")
    @test match(bare_words, sentence_with_handles).match == ss("dood23")
    ellipsis = r"(?:\.(?:\s*\.){1,})"           # Ellipsis dots.
    misc = r"(?:\S)"
  end
  @test tweet_tokenize(default_vectorizer, multi_sent) == tokenized_output

  end
  @testset "count model utils" begin
    @testset "word models" begin
      input_sents = ["Hey, this is a test sentence!",
                    "What do you think this will do?"]
      @testset "n-gram range 1" begin
        #Testing with default arguments
        vectorizer = CountVectorizer()
        target_res = ["hey",",","this","is","a","test","sentence","!",
                      "what","do","you","think","will","?"]
        fit!(vectorizer, input_sents)
        @test sort(vectorizer.vocabulary) == sort(target_res)
        example_matrix = [1 1 0 1 0 1 1 1 1 0 1 0 0 0; 0 0 1 0 1 0 0 0 0 1 1 1 1 1]
        example_matrix = sparse(example_matrix)
        @test transform(vectorizer, input_sents) == example_matrix
        vectorizer2 = CountVectorizer()
        @test fit_transform!(vectorizer, input_sents) == example_matrix
      end
      @testset "larger n-grams" begin
        vectorizer = CountVectorizer(ngram_range=(2,4))

      end
    end
    @testset "masking" begin
      @testset "binary" begin
        labels = [0,1,1,0,1,0,0,0]
        target = Dict(0 => [true, false, false, true, false, true, true, true],
                      1 => [false, true, true, false, true, false, false, false])
        @test target == create_bool_masks(labels)
      end
      @testset "multi-class" begin
        labels = [1,2,3,0,0,2,2,3]
        target = Dict(0 => [false, false, false, true, true, false, false, false],
                      1 => [true, false, false, false, false, false, false, false],
                      2 => [false, true, false, false, false, true, true, false],
                      3 => [false, false, true, false, false, false, false, true])
        @test target == create_bool_masks(labels)
      end
    end
  end
end
