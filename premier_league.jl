using CSV, DataFrames, JuMP, HiGHS, TidierData

premier_league = CSV.read("male_players.csv", DataFrame)
data = CSV.read("male_players.csv", DataFrame)


premier_league = @chain premier_league begin
    TidierData.@filter(fifa_version == 24.0)
    TidierData.@filter(league_name == "Premier League")
    TidierData.@separate(player_positions, (a,b,c), ", ")
    TidierData.@select(-(b:c))
    end
rename!(premier_league, :a => "first_position")
premier_league = dropmissing(premier_league, [:value_eur, :wage_eur])

data = @chain data begin
    TidierData.@filter(fifa_version == 24.0)
    TidierData.@select(player_id, short_name, player_positions, overall, potential, value_eur, wage_eur, club_team_id, club_name, league_id,
    league_name, club_position, nationality_name, release_clause_eur,pace, shooting, passing, dribbling, defending,
    physic)
    TidierData.@separate(player_positions, (a,b,c), ", ")
    TidierData.@select(-(b:c))    
    end
data = dropmissing(data, [:value_eur, :wage_eur])
rename!(data, :a => "first_position")
 unique(data."first_position")

premier_league = premier_league[(premier_league.club_name .!= "Shakhtar Dontesk") .& (premier_league.club_name .!= "Dynamo Kyiv"), :]

clubs = @chain premier_league begin
    TidierData.@group_by(club_name, first_position)
    TidierData.@summarise(mean_overall = sum(overall), sum_shooting = sum(shooting), 
    sum_passing = sum(passing), sum_dribbling = sum(dribbling), sum_defending = sum(defending),
    sum_physic = sum(physic))
    TidierData.@ungroup
end

club_positions = @chain premier_league begin
    TidierData.@group_by(club_name, first_position)
    TidierData.@summarise(n_players = length(first_position))
    TidierData.@ungroup
end


club_budget = @chain premier_league begin
    TidierData.@group_by(club_name)
    TidierData.@summarise(transfer_budget = sum(value_eur), wage_budget = sum(wage_eur))
end

function get_nplayers(clube, posicao)
    x = club_positions[(club_positions.club_name .== clube) .& (club_positions.first_position .== posicao), :n_players]
    if isempty(x)
        push!(x, 0)
    else
        x
    end
end

function get_skill(clube, position)
    if position in ["ST","CF"]
        x = clubs[(clubs.first_position .== position) .& (clubs.club_name .== clube), "sum_shooting"]
    elseif position in ["LW","RW"]
        x= clubs[(clubs.first_position .== position) .& (clubs.club_name .== clube), "sum_dribbling"]
    elseif position in ["CM", "CDM", "CAM", "RM", "LM"]
        x= clubs[(clubs.first_position .== position) .& (clubs.club_name .== clube), "sum_passing"]
    elseif position in ["RB", "LB", "LWB", "RWB"]
        x= clubs[(clubs.first_position .== position) .& (clubs.club_name .== clube), "sum_physic"]
    elseif position in ["CB"]
        x= clubs[(clubs.first_position .== position) .& (clubs.club_name .== clube), "sum_defending"]
    else  position in ["GK"]
        x=clubs[(clubs.first_position .== position) .& (clubs.club_name .== clube), "mean_overall"]
    end

    if isempty(x)
        return 0
    else
        return x[1]
    end
end

function  get_wage(clube)
    club_budget[club_budget.club_name .== clube, "wage_budget"] 
end


function  get_transfer(clube)
    club_budget[club_budget.club_name .== clube, "transfer_budget"] 
end

for position in unique_positions
    x = data[!, position] = data.first_position .== position
end

function skill(posicao)
    if posicao in ["ST","CF"]
        teste[!, "shooting"]
    elseif posicao in ["LW","RW"]
        teste[!, "dribbling"]
    elseif posicao in ["CM", "CDM", "CAM", "RM", "LM"]
        teste[!, "passing"]
    elseif posicao in ["RB", "LB", "LWB", "RWB"]
        teste[!, "physic"]
    elseif posicao in ["CB"]
        teste[!, "defending"]
    else
        teste[!,"overall"]
    end
end




teste = data[:,:] 
teste = coalesce.(teste, 0)
model = Model(HiGHS.Optimizer)
budget_constraint = get_transfer("Liverpool")[1]
wage_constraint = get_wage("Liverpool")[1]
@variable(model, x[teste.player_id] >= 0, Bin)
teste.x = Array(x)
@constraint(model,[i = 1:length(unique_positions)], sum(teste[!, unique_positions[i]] .* teste.x) == get_nplayers("Liverpool", unique_positions[i])[1])
@constraint(model,[i = 1:length(unique_positions)],sum((skill(unique_positions[i]) .* teste.x)) >= get_skill("Liverpool", unique_positions[i]))
@constraint(model, sum(teste.value_eur .* teste.x) <= budget_constraint)
@constraint(model, sum(teste.wage_eur .* teste.x) <= wage_constraint)
@objective(model, Max, sum(teste.overall .* teste.x))


optimize!(model)
solution_summary(model)


result = @chain teste begin
    TidierData.@filter(value((x)) == 1)
    TidierData.@group_by(first_position)
    @ungroup
end

comparativo = @chain data begin
    TidierData.@filter(club_name == "Liverpool")
    TidierData.@summarise(mean_overall = mean(overall), mean_potential = mean(potential))
end

