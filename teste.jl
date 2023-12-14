using CSV, DataFrames, JuMP, HiGHS, TidierData

data = CSV.read("male_players.csv", DataFrame)

data = @chain data begin
    TidierData.@filter(fifa_version == 24.0)
    TidierData.@select(player_id, short_name, player_positions, overall, potential, value_eur, wage_eur, age, club_team_id, club_name, league_id,
    league_name, club_position, nationality_name, release_clause_eur,pace, shooting, passing, dribbling, defending,
    physic)
    TidierData.@separate(player_positions, (a,b,c), ", ")
    TidierData.@select(-(b:c))    
    end
data = dropmissing(data, [:value_eur, :wage_eur])
rename!(data, :a => "first_position")
 unique(data."first_position")


gk_peak_age = 28
gk_old_age = 35

function gk(data, gk_peak_age, gk_old_age)
    if data.age .> gk_old_age
        data.ano_1 = overall - 1
    elseif data.age < gk_peak_age && data.overall .< data.potential
        data.ano_1 = data.overall .+ (data.potential - data.overall  / (gk_peak_age - data.age))
    else
        data.ano_1 = data.overall
    end
end


if data[:,(data.age .> gk_old_age)] == true  
    print("ok")
end 

for i = 1:5
     p = 0
     colname = "forward_$i"
     data[!,colname] .= p
end



x = data[(data.age .> 28) .& (data.first_position .== "CB") .& (data.overall .< data.potential), :]

#GOALKEEPER
data = @chain data begin
        @mutate(forward_1 = case_when( 
        (first_position .== "GK") .& (overall .< potential) .=> min(overall + (potential - overall) / (32 - age)),
        (first_position .== "GK") .& (overall .>= potential) .& (age+1 .>=35).=> overall - 1,
        true => overall))    
        @mutate(forward_2 = case_when( 
        (first_position .== "GK") .& (overall .< potential) .=> min(potential,overall + (potential - overall) / (32 - age)*2),
        (first_position .== "GK") .& (overall .>= potential) .& (age+2 .>=35).=> forward_1 - 1,
        true => forward_1))
        @mutate(forward_3 = case_when( 
            (first_position .== "GK") .& (overall .< potential) .=> min(potential,overall + (potential - overall) / (32 - age)*3),
            (first_position .== "GK") .& (overall .>= potential) .& (age+3 .>=35).=> forward_2 - 1,
            true => forward_2))
        @mutate(forward_4 = case_when( 
            (first_position .== "GK") .& (overall .< potential) .=> min(potential,overall + (potential - overall) / (32 - age)*4),
            (first_position .== "GK") .& (overall .>= potential) .& (age+4 .>=35).=> forward_3 - 1,
            true => forward_3))
        @mutate(forward_5 = case_when( 
            (first_position .== "GK") .& (overall .< potential) .=> min(potential,overall + (potential - overall) / (32 - age)*5),
            (first_position .== "GK") .& (overall .>= potential) .& (age+5 .>=35).=> forward_4 - 1,
            true => forward_4))        
end

#CETERBACK APEX 31, DECLINING AGE 33
data = @chain data begin
    @mutate(forward_1 = case_when( 
    (first_position .== "CB") .&  (age+1 .>=33).=> overall - 1,
    (first_position .== "CB") .& (overall .< potential) .=> min(overall + (potential - overall) / (31 - age)),
    true => forward_1))    
    @mutate(forward_2 = case_when( 
    (first_position .== "CB") .& (age+2 .>=33).=> forward_1 - 1,
    (first_position .== "CB") .& (forward_1 .< potential) .=> min(potential,overall + (potential - overall) / (31 - age)*2),
    true => forward_2))
    @mutate(forward_3 = case_when( 
    (first_position .== "CB") .& (age+3 .>=33).=> forward_2 - 1,    
    (first_position .== "CB") .& (forward_2 .< potential) .=> min(potential,overall + (potential - overall) / (31 - age)*3),
    true => forward_3))
    @mutate(forward_4 = case_when( 
    (first_position .== "CB")  .& (age+4 .>=33).=> forward_3 - 1,
    (first_position .== "CB") .& (forward_3 .< potential) .=> min(potential,overall + (potential - overall) / (31 - age)*4),
    true => forward_4))
    @mutate(forward_5 = case_when( 
    (first_position .== "CB") .& (age+5 .>=33).=> forward_4 - 1,    
    (first_position .== "CB") .& (forward_4 .< potential) .=> min(potential,overall + (potential - overall) / (31 - age)*5),
    true => forward_5))        
end

y = unique(data.first_position) 
println(y)

#lb peak age 28
x = data[(data.age .>= 27) .& (data.first_position .== "LB") .& (data.overall .< data.potential), :]

#st peak age 28
x = data[(data.age .>= 27) .& (data.first_position .== "ST") .& (data.overall .< data.potential), :]

#cm peak AGE 28
x = data[(data.age .>= 27) .& (data.first_position .== "CM") .& (data.overall .< data.potential), :]
#cb peak AGE30
x = data[(data.age .>= 29) .& (data.first_position .== "CB") .& (data.overall .< data.potential), :]
#cf peak age 28
x = data[(data.age .>= 27) .& (data.first_position .== "CF") .& (data.overall .< data.potential), :]
#gk peak age 31
x = data[(data.age .>= 30) .& (data.first_position .== "GK") .& (data.overall .< data.potential), :]
#LW peak age 27
x = data[(data.age .>= 26) .& (data.first_position .== "LW") .& (data.overall .< data.potential), :]
#CDM peak age 29
x = data[(data.age .>= 28) .& (data.first_position .== "CDM") .& (data.overall .< data.potential), :]
#RW peak age 27
x = data[(data.age .>= 26) .& (data.first_position .== "RW") .& (data.overall .< data.potential), :]
#CAM peak age 28
x = data[(data.age .>= 27) .& (data.first_position .== "CAM") .& (data.overall .< data.potential), :]
#RB peak age 28
x = data[(data.age .>= 27) .& (data.first_position .== "RB") .& (data.overall .< data.potential), :]
#Rm peak age 27
x = data[(data.age .>= 26) .& (data.first_position .== "RM") .& (data.overall .< data.potential), :]
#LM peak age 27
x = data[(data.age .>= 26) .& (data.first_position .== "LM") .& (data.overall .< data.potential), :]
#LWB peak age 28
x = data[(data.age .>= 27) .& (data.first_position .== "LWB") .& (data.overall .< data.potential), :]
#RWB peak age 28
x = data[(data.age .>= 27) .& (data.first_position .== "RWB") .& (data.overall .< data.potential), :]


for role in y
    if role in ["ST","LB","CM","CF","CAM","RB","LWB","RWB"]
        peak_age = 28
        declining_age = peak_age + 5
    elseif role in ["LW","RW","RM","LM"]
        peak_age = 27
        declining_age = peak_age + 5
    elseif role == "GK"
        peak_age = 31
        declining_age = peak_age + 5
    elseif role == "CB"
        peak_age = 30
        declining_age = peak_age + 5
    elseif role == "CDM"
        peak_age = 29
        declining_age = peak_age + 5
    end
    data = @chain data begin
        @mutate(forward_1 = case_when( 
        (first_position .== !!role) .&  (age+1 .>=!!declining_age).=> overall - 1,
        (first_position .== !!role) .& (overall .< potential) .=> min(overall + (potential - overall) / (!!peak_age - age)),
        true => forward_1))    
        @mutate(forward_2 = case_when( 
        (first_position .== !!role) .& (age+2 .>=!!declining_age).=> forward_1 - 1,
        (first_position .== !!role) .& (forward_1 .< potential) .=> min(potential,overall + (potential - overall) / (!!peak_age - age)*2),
        true => forward_2))
        @mutate(forward_3 = case_when( 
        (first_position .== !!role) .& (age+3 .>=!!declining_age).=> forward_2 - 1,    
        (first_position .== !!role) .& (forward_2 .< potential) .=> min(potential,overall + (potential - overall) / (!!peak_age - age)*3),
        true => forward_3))
        @mutate(forward_4 = case_when( 
        (first_position .== !!role)  .& (age+4 .>=!!declining_age).=> forward_3 - 1,
        (first_position .== !!role) .& (forward_3 .< potential) .=> min(potential,overall + (potential - overall) / (!!peak_age - age)*4),
        true => forward_4))
        @mutate(forward_5 = case_when( 
        (first_position .== !!role) .& (age+5 .>=!!declining_age).=> forward_4 - 1,    
        (first_position .== !!role) .& (forward_4 .< potential) .=> min(potential,overall + (potential - overall) / (!!peak_age - age)*5),
        true => forward_5))        
    end
end

length(y)

for i in range(1,length(y))
    print(i)
end

role = "CB"
peak_age =30
declining_age = 25
@chain data begin
    @mutate(forward_1 = case_when( 
    (first_position == !!role) .&  (age+1 .>=!!declining_age).=> overall - 1,
    (first_position == !!role) .& (overall .< potential) .=> min(overall + (potential - overall) / (!!peak_age - age)),
    true => forward_1))    
    @mutate(forward_2 = case_when( 
    (first_position .== !!role) .& (age+2 .> 30).=> forward_1 - 1,
    (first_position .== !!role) .& (forward_1 .< potential) .=> min(potential,overall + (potential - overall) / (!!peak_age - age)*2),
    true => forward_2))
    @mutate(forward_3 = case_when( 
    (first_position .== !!role) .& (age+3 .>=!!declining_age).=> forward_2 - 1,    
    (first_position .== !!role) .& (forward_2 .< potential) .=> min(potential,overall + (potential - overall) / (!!peak_age - age)*3),
    true => forward_3))
    @mutate(forward_4 = case_when( 
    (first_position .== !!role)  .& (age+4 .>=!!declining_age).=> forward_3 - 1,
    (first_position .== !!role) .& (forward_3 .< potential) .=> min(potential,overall + (potential - overall) / (!!peak_age - age)*4),
    true => forward_4))
    @mutate(forward_5 = case_when( 
    (first_position .== !!role) .& (age+5 .>=!!declining_age).=> forward_4 - 1,    
    (first_position .== !!role) .& (forward_4 .< potential) .=> min(potential,overall + (potential - overall) / (!!peak_age - age)*5),
    true => forward_5))        
end



function forward_year(DataFrame,forward_year)

    for i in range(1,length(forward_year))

        if DataFrame.first_position in ["ST","LB","CM","CF","CAM","RB","LWB","RWB"]
            peak_age = 28
            declining_age = peak_age + 5
            if (DataFrame.age .+ 1) .>= declining_age
                result, DataFrame.overall .- 1  
            elseif DataFrame.overall .<= DataFrames.potential
                result = min(DataFrame.potential, DataFrame.overall .+ (DataFrame.potential .- DataFrame.overall) ./ (peak_age.-DataFrame.age).*i) 
            else    
                result = DataFrame.overall
            end
        elseif DataFrame.first_position in ["LW","RW","RM","LM"]
            peak_age = 27
            DataFrame.first_position = peak_age + 5
            if (DataFrame.age .+ 1) .>= declining_age
                result = DataFrame.overall .- 1  
            elseif DataFrame.overall .<= DataFrames.potential
                result = min(DataFrame.potential, DataFrame.overall .+ (DataFrame.potential .- DataFrame.overall) / (peak_age .- DataFrame.age).*i) 
            else    
                result =DataFrame.overall 
            end
        elseif DataFrame.first_position == "GK"
            peak_age = 31
            declining_age = peak_age + 5
            if (DataFrame.age .+ 1) .>= declining_age
                result =DataFrame.overall .- 1  
            elseif DataFrame.overall .<= DataFrames.potential
                result = min(DataFrame.potential, DataFrame.overall .+ (DataFrame.potential .- DataFrame.overall) / (peak_age.-DataFrame.age).*i) 
            else    
                result =DataFrame.overall
            end
        elseif DataFrame.first_position == "CB"
            peak_age = 30
            declining_age = peak_age + 5
            if (DataFrame.age .+ 1) .>= declining_age
                result =DataFrame.overall .- 1  
            elseif DataFrame.overall .<= DataFrames.potential
                result =min(DataFrame.potential, DataFrame.overall + (DataFrame.potential - DataFrame.overall) / (peak_age.-DataFrame.age).*i) 
            else    
                result =DataFrame.overall
            end
        elseif DataFrame.first_position == "CDM"
            peak_age = 29
            declining_age = peak_age + 5
            if (DataFrame.age .+ 1) .>= declining_age
                result =DataFrame.overall .- 1  
            elseif DataFrame.overall .<= DataFrames.potential
                result =min(DataFrame.potential, DataFrame.overall .+ (DataFrame.potential - DataFrame.overall) / (peak_age.-DataFrame.age).*i) 
            else    
                result = DataFrame.overall
            end
        
        print(result)
        end
    end
    print(result)
end

forward_year(data, 5)

using TidierData

df = DataFrame(a = string.(repeat('a':'e', inner = 2)),
               b = [1,1,1,2,2,2,3,3,3,4],
               c = 11:20)

myvar_string = "b"
@chain df begin
    @filter(a == !!myvar_string)
end

df = DataFrame(a = string.(repeat('a':'e', inner = 2)),
               b = [1,1,1,2,2,2,3,3,3,4],
               c = 11:20)

col= [:b, :c]
@chain df begin
  @summarize(across(!!col, mean))
  println
end
#end

data.first_position .== "GK"