puts "Simple GA Phrase in Crystal"

goal_phrase = "Donald Trump is a traitor."
population_size = 200
mating_pool_multiplier = goal_phrase.size * 50
mutation_rate = 0.01
solution_limit = 0.99

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

solved = false
iteration = 0
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
    elsif ind.fitness > best_ever.fitness
      best_ever = ind
    elsif ind.fitness > best_this_loop.fitness
      best_this_loop = ind
    end
    mating_pool << best_ever
    mating_pool << best_this_loop
    (ind.fitness * mating_pool_multiplier).to_i.times { mating_pool << ind }
    mating_pool << best_ever
    mating_pool << best_this_loop
  end

  puts "#{best_this_loop.to_s}\t#{iteration += 1}"

  # crossover if not solved
  if !solved
    population_size.times do |i|
      population[i] = mating_pool[Random.rand(mating_pool.size)].crossover(mating_pool[Random.rand(mating_pool.size)])
    end
  end

# end main while loop
end

puts " "
population.each do |ind|
  puts "Solution: #{ind.to_s}" if ind.solution
end
