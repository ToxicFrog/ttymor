-- simple test pattern for 256-color support

for r=0,255,32 do
  for g=0,255,32 do
    for b=0,255,32 do
      io.write('\x1B[38;2;'..r..';'..g..';'..b..'m@')
    end
    io.write ' '
  end
  io.write('\n')
end
