using TextAnalysis
using Random
"""
    `read_movie_dataset(file_path::String)`

Read in the sentiment dataset from
[Maas 2011](http://ai.stanford.edu/~amaas/data/sentiment/)

This returns an array of strings (the file contents) and an array of labels
"""
function read_movie_dataset(file_path::String)
    neg_data = []
    pos_data = []
    for (root, dirs, files) in walkdir(file_path * "/neg")
        for file in files
            text = Document(readlines(joinpath(root, file)))
            push!(neg_data, text)
        end
    end
    for (root, dirs, files) in walkdir(file_path * "/pos")
        for file in files
            text = Document(readlines(joinpath(root, file)))
            push!(pos_data, text)
        end
    end
    neg_labels = repeat([0], length(neg_data))
    pos_labels = repeat([1], legnth(pos_data))
    labels = vcat(neg_labels, pos_labels)
    data = vcat(neg_data, pos_data)
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
        push!(sentiments, model(document))
    end
    res = [sentiment >= 0.5 ? 1 : 0 for sentiment in sentiments]
    return res
end
function main()
    data, labels = read_movie_dataset("aclImdb/test/")
    data, labels = shuffle_data()
end
