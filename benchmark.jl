using TextAnalysis
using Random
"""
    `read_movie_dataset(file_path::String)`

Read in the sentiment dataset from
[Maas 2011](http://ai.stanford.edu/~amaas/data/sentiment/)

This returns an array of strings (the file contents) and an array of labels
"""
function read_movie_dataset(file_path::String)
    neg_data = DirectoryCorpus(file_path * "/neg")
    pos_data = DirectoryCorpus(file_path * "/pos")
    standardize!(neg_data, StringDocument)
    standardize!(pos_data, StringDocument)
    # Preprocessing
    prepare!(neg_data, strip_case)
    prepare!(pos_data, strip_case)
    prepare!(neg_data, strip_punctuation)
    prepare!(pos_data, strip_punctuation)
    prepare!(pos_data, strip_stopwords)
    prepare!(neg_data, strip_stopwords)
    #for (root, dirs, files) in walkdir(file_path * "/neg")
    #    for file in files
    #        text = StringDocument(readlines(joinpath(root, file)))
    #        push!(neg_data, text)
    #    end
    #end
    #for (root, dirs, files) in walkdir(file_path * "/pos")
    #    for file in files
    #        text = StringDocument(readlines(joinpath(root, file)))
    #        push!(pos_data, text)
    #    end
    #end

    neg_labels = repeat([0], length(neg_data))
    pos_labels = repeat([1], length(pos_data))
    labels = vcat(neg_labels, pos_labels)
    data = vcat(neg_data.documents, pos_data.documents)
    return data, labels
end
"""
    `shuffle_data(seed, iterables...)`

This is a simple function that shuffles the given arrays
using the specified seed.

It returns a tuple with as many elements as those contained in `iterables`
"""
function shuffle_data(iterables...;seed=1423310)
    target_length = length(iterables[1])
    for iterable in iterables
        if length(iterable) != target_length
            error("Length of iterables to shuffle do not match")
        end
    end
    indexes = collect(1:target_length)
    shuffle!(indexes)
    shuffled_iterables = []
    for iterable in iterables
        push!(shuffled_iterables, iterable[indexes])
    end
    return Tuple(shuffled_iterables)
end
"""
    `sentiment_score(data::Array)`

Calculate the sentiment score for each document in data
    the results returned are binarized:
        - Labels above 0.5 are raised to 1
        - Labels below 0.5 are lowered to 0
        - Labels of exactly 0.5 are raised
"""
function sentiment_score(data::Array)
    model = SentimentAnalyzer()
    sentiments = Float64[]
    for document in data
        toked_document = TokenDocument(text(document))
        # This next line has to be done as the word embeddings are only 5000 long
        toked_document.tokens = [ token for token in toked_document.tokens
                                  if token in keys(model.model.words) && model.model.words[token] < 5000]
        try
            push!(sentiments, model(toked_document))
        catch MethodError
            n_tokens = length(toked_document.tokens)
            if n_tokens <= 500
                println(n_tokens)
            end
            push!(sentiments, 0.5)
        end
    end
    res = [sentiment > 0.5 ? 1 : 0 for sentiment in sentiments]
    return res, sentiments
end
"""
Calculate the accuracy of the algorithm
"""
function accuracy(y, labels)
    if length(y) != length(labels)
        error("Length of labels and predicted values do not match")
    end
    match_count = sum([y[i] == labels[i] ? 1 : 0 for i=1:length(labels)])
    return Float64(match_count)/length(y)
end
function write_predictions(sentiments, preds, labels, file_path)
    out_fp = open(file_path, "w")
    for i in eachindex(sentiments)
        pred = preds[i]
        sentiment = sentiments[i]
        label = labels[i]
        write(out_fp, string(pred) * "\t" * string(sentiment) * "\t" * string(label) * "\n")
    end
end
function main()
    println("Reading in datasets")
    data, labels = read_movie_dataset("aclImdb/test/")
    println("Shuffling data...")
    data, labels = shuffle_data(data, labels)
    println("Scoring sentiment")
    y, sentiments = sentiment_score(data)
    println("Computing Accuracy")
    acc = accuracy(y, labels)
    write_predictions(sentiments, y, labels, "predictions.txt")
    println(acc)
    y_filtered = []
    labels_filtered = []
    for i in eachindex(y)
        push!(y_filtered, y[i])
        push!(labels_filtered, labels[i])
    end
    new_acc = accuracy(y_filtered, labels_filtered)
    println(new_acc)

end
main()
