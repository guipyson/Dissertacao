using CSV, DataFrames, JuMP, HiGHS, TidierData

data = CSV.read("male_players.csv", DataFrame)
 
data = @chain data begin
    TidierData.@filter(fifa_version == 24.0)
    TidierData.@select(short_name, player_positions, overall, potential, value_eur, wage_eur, club_team_id, club_name, league_id,
    league_name, club_position, nationality_name, release_clause_eur,pace, shooting, passing, dribbling, defending,
    physic)
    TidierData.@separate(player_positions, (a,b,c), ", ")
    TidierData.@select(-(b:c))
    end


rename!(data, :a => "best_position")
unique_positions = unique(data."best_position")

for position in unique_positions
    data[!, position] = data.best_position .== position
end


teste = data[1:50,:]
model = Model(HiGHS.Optimizer)
budget_constraint = 1000000000000
wage_constraint = 1000000000000
@variable(model, x[teste.short_name] >= 0, Bin)
teste.x = Array(x)
for position in unique_positions
    @constraint(model, sum(teste[!, position] .* teste.x) <= 1)
end
@constraint(model, sum(teste.value_eur .* teste.x) <= budget_constraint)
@constraint(model, sum(teste.wage_eur .* teste.x) <= wage_constraint)
@objective(model, Max, sum(teste.overall .* teste.x))
###teste.x = Array(x)
#@objective(model, Max, sum(teste.overall));
#print(model)

optimize!(model)
solution_summary(model)

for row in eachrow(teste)
    println(row.short_name, " = ", value(row.x))
end
