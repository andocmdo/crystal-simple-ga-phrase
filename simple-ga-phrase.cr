require "http/server"

puts "Simple GA Phrase in Crystal"

goal_phrase = "A fool thinks himself to be wise, but a wise man knows himself to be a fool."
population_size = 200
multiplier = 20
mating_pool_multiplier = goal_phrase.size * multiplier
mutation_rate = 0.01
solution_limit = 0.999

character_pool = Array(Char).new()
('a'..'z').each do |c|
  character_pool << c
end
('A'..'Z').each do |c|
  character_pool << c
end
[' ','.','!','?',','].each do |c|
  character_pool << c
end


class Individual
  @fitness = 0.0
  @solution = false
  getter dna : Array(Char)
  getter fitness
  property solution

  def initialize(size : Int32, available_chars : Array(Char))
    @dna = Array(Char).new(size) { available_chars[Random.rand(available_chars.size)] }
  end

  def initialize(@dna : Array(Char))
  end

  def fitness(phrase : Array(Char))
    score = 0.0
    phrase.each_with_index do |c, i|
      if c == @dna[i]
        score += 1
      end
    end
    @fitness = score / phrase.size
  end

  def crossover(partner : Individual)
    new_dna = Array(Char).new
    partner.dna.each_with_index do |pc, i|
      new_dna << ([true, false].sample ? pc : @dna[i])
    end
    Individual.new(new_dna)
  end

  def mutate(rate : Float64, available_chars : Array(Char))
    @dna = @dna.map { |c| Random.rand(1.0) < rate ? available_chars[Random.rand(available_chars.size)] : c }
  end

  def to_s
    @dna.join
  end
# Individual Class end
end

# Initialize the population
population = Array(Individual).new(population_size) {Individual.new(goal_phrase.size, character_pool)}
best_ever = population[0]
best_this_loop = population[0]
solved = false
solution = ""
iteration = 0

spawn do
  while !solved
    #puts "#{best_ever.to_s}\t#{iteration += 1}"
    best_this_loop = population[0]
    mating_pool = Array(Individual).new

    # mutate and fitness in the same loop, why not?
    # shoot, why not even feed the mating pool too while we are at it?
    population.each do |ind|
      ind.mutate(mutation_rate, character_pool)
      if ind.fitness(goal_phrase.chars) > solution_limit
        solved = true
        ind.solution = true
        solution = ind.to_s
      elsif ind.fitness > best_ever.fitness
        best_ever = ind
      elsif ind.fitness > best_this_loop.fitness
        best_this_loop = ind
      end
      (ind.fitness * mating_pool_multiplier).to_i.times { mating_pool << ind }
      # This adds the best-this-loop and the best-ever into the mating pool, just a bit, 3 individuals each.
      # Helps to push the evolution to the solution faster
      20.times do
        mating_pool << best_ever
      end
    end

    puts "#{best_this_loop.to_s}\t#{iteration += 1}"

    # crossover if not solved
    if !solved
      population_size.times do |i|
        population[i] = mating_pool[Random.rand(mating_pool.size)].crossover(mating_pool[Random.rand(mating_pool.size)])
      end
    end

  # end main while loop
    Fiber.yield
  end

  puts " "
  population.each do |ind|
    puts "Solution: #{ind.to_s}" if ind.solution
  end
end


server = HTTP::Server.new do |context|
  context.response.content_type = "text/plain"
  context.response.print "Generation: #{iteration}\n"
  context.response.print "Best so far: #{best_ever.to_s}\n"
  context.response.print "Best last loop: #{best_this_loop.to_s}\n"
  context.response.print "Solved?: #{solved}\n"
  context.response.print "Solution: #{solution}\n"
  context.response.print "Request: #{context.request.path}"
  context.response.print "\n\n"

# Next, use the url request string to change the phrase, and variables. Even while it is running!!!
#"/Blakjdf%20/3/489".split('/')
#URI.unescape("/Blakjdf%20/3/489")
# localhost:8080/phrase/popsize/multiplier/mutrate/solved
request_parts = context.request.path.split('/')
if request_parts.size == 6
  phrase = URI.unescape(request_parts[1])
  population_size = URI.unescape(request_parts[2]).to_i
  multiplier = URI.unescape(request_parts[3]).to_i
  mutation_rate = URI.unescape(request_parts[4]).to_f
  if URI.unescape(request_parts[5]) == "false"
    solved = false
  elsif URI.unescape(request_parts[5]) == "true"
    solved = true
  end
end

  population.each do |ind|
    context.response.print "#{ind.to_s}\n"
  end
end

puts "Listening on http://127.0.0.1:8080"
server.listen(8080)
