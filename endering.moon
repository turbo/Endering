inspect = require "inspect"

class Enderer
  dict = {}
  state: {}

  new: =>
    for w in io.lines("words")
      dict[w] = true

  guess: (w, bl=nil) =>
    @state =
      input: w
      current: w
      clength: w\len!
      verbatim: false
      blacklist: {}

    if bl
      for w in *bl
        @state.blacklist[w] = true

    b = @run!

    if b
      @state.current
    elseif @state.verbatim
      @state.input
    else
      "<impossible> (stopped at: #{@state.current})"

  try: => not @state.blacklist[@state.current] and dict[@state.current] 

  set: (w) =>
    @state.current = w
    @state.clength = w\len!

  cutoff: (s) =>
    @set @state.current\sub 1, (@state.clength - s\len!)

  qend: (s) =>
    q = @state.current\sub (@state.clength - s\len! + 1)
    q == s and q or nil

  nth: (n) =>
    r = @state.current\reverse!
    r\sub(n, n)

  qnth: (s, n) => s == @nth n

  add: (s) => @state.current ..= s

  vowel: (s) =>
    return switch s
      when "a", "e", "i", "o", "u", "y" then true
      else false

  liquid: (s) =>
    return switch s
      when "l", "r", "s", "v", "z" then true
      else false 

  noend: (s) =>
    return switch s
      when "c", "g", "s", "v", "z" then true
      else false

  run: =>
    @state.verbatim = @try!
    
    if co = @qend "n't"
      @cutoff co
      return @try!

    if co = @qend "'s"
      @cutoff co
      return @try!

    cta = false
    if co = @qend "'"
      @cutoff co
      cta = true

    if cta or @qend("s")
      @cutoff "s"
      return @try! unless @qnth "e", 1

      if @qnth "i", 2
        @cutoff "ie"
        @add "y"
        return @try!
      elseif @qnth "h", 2
        @cutoff "e" unless @qnth "t", 3
        return @try!
      elseif @qnth "x", 2
        @cutoff "e"
        return @try!
      elseif @qnth("s", 2) or @qnth("z", 2)
        @cutoff "e" if @qnth("s", 3) or @qnth("z", 3)
        return @try!
      elseif @qnth "v", 2
        return true if @try!
        @cutoff "ve"
        @add "fe"
        return @try!
      else
        return @try!
    elseif co = @qend "ly"
      @cutoff co
      unless @qnth "i", 1
        return true if @try!
        @add "le"
        return @try!
      else
        @cutoff "i"
        @add "y"
        return @try!
    else
      -- snip
      if co = @qend "ing"
        @cutoff co
      elseif co = @qend "ed"
        @cutoff co
      elseif co = @qend "en"
        @cutoff co
      elseif co = @qend "er"
        @cutoff co
      elseif co = @qend "est"
        @cutoff co
      else
        return false

      if @vowel @nth 1
        if @qnth "i", 1
          @cutoff "i"
          @add "y"
          return @try!
        elseif @qnth "y", 1
          return @try!
        elseif @qnth "e", 1
          if @qnth "e", 2
            return @try!
          else
            return true if @try!
            @add "e"
            return @try!
        else
          @add "e"
          return @try!
      else -- consonant (liquid, noendc)
        if @qnth "h", 1
          unless @qnth "t", 2
            return @try!
          else
            return true if @try!
            @add "e"
            return @try!
        elseif @nth(1) == @nth(2)
          if @liquid @nth 1
            return true if @try!
          @cutoff @nth 1
          return @try!
        elseif @vowel @nth 2
          if @vowel @nth 3
            @add "e" if @noend @nth 1
            return @try!
          else
            @add "e"
            return @try!
        else
          if @liquid @nth 1
            return @try! if @qend "rl"
            @add "e"
            return @try!
          else
            @add "e" if @noend @nth 1
            return @try!


ti = Enderer!

tc = (w, bl=nil) -> print w .. " -> " .. ti\guess w, bl
tcc = (c, bl=nil) -> tc w, bl for w in *c

-- These are pretty unambigous cases, all resolving correctly
print "# Standard test cases:"
tcc {
  "don't"
  "don'tnonsense"
  "bashes"
  "bathes"
  "leaning"
  "lean"
  "leaving"
  "dented"
  "danced"
  "dogs"
  "kisses"
  "curved"
  "curled"
  "rotting"
  "rolling"
  "patrolled"
  "played"
  "plied"
  "realest"
  "palest"
  "prettily"
  "ran"
  "running"
  "run"
}

-- Now a practical demonstration of why "technically correct"
-- is sometimes still "kinda wrong". Try to guess what the
-- following test cases output:

print "\n# Ambigous cases:"
tcc { "knives", "nobly" }

-- You might have expected "knife" and "noble". However, 
--
--   - "knives" will become "knive", since "knive" is a valid
--     word in our dictionary (a less common alt. to "knife")
--
--   - "nobly" will become "nob" (british slang for a noble 
--     person). As such, "nobly" is the adverbial form (to
--     "be like a nob") of "nob" rather than of "noble".
--
-- We can fix this by removing those weird words. This shows
-- that this is not a bug in the parser:

print "\n# Blacklist applied:"
tcc { "knives", "nobly" }, { "knive", "nob" }
