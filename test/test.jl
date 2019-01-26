using Test
include("../benchmark.jl")
@testset "shuffle" begin
  input = [3,1,2,1,9]
  output  = shuffle(input)
  @test typeof(input) == typeof(output)
  @test length(input) == length(output)
  @test sort(output) == sort(input)
  input2 = [1938,283,1902,110,1,10]
  @test_throws ErrorException output1, output2 = shuffle_data(input, input2)
  input2 = [1938, 283, 1902, 110, 1]
  output1, output2 = shuffle_data(input, input2)
  @test sort(output1) == sort(input)
  @test sort(output2) == sort(input2)
end

@testset "accuracy" begin
  y = [1,1,1,0,0,1]
  labels = [1,1,1,1,0,1]
  @test accuracy(y, labels) == 1.0-1/6
end
