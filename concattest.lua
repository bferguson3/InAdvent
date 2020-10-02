local r1, r2 = 0, 0
for i=1,100 do 
    t_a = os.clock()
    for i=1,10000 do 
        s = 'a' .. 'b' .. 'c'
    end
    t_b = os.clock()
    for i=1,10000 do 
        s = string.format('a%s%s', 'b', 'c')
    end
    t_c = os.clock()
    r1 = r1 + (t_b-t_a)
    r2 = r2 + (t_c-t_b)
end
print('1M .. concats vs 1M fprints:')
print(r1 .. ' vs ' .. r2)