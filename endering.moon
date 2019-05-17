inspect = require "inspect"

class Enderer
  dict = {}

  current: ""
  verbatim: false
  blacklist: {}

  new: => dict[w] = true for w in io.lines("words")

  guess: (w, bl=nil) =>
    @current = w

    if bl then @blacklist[wi] = true for wi in *bl
    @verbatim = @try!
    b = @run!

    if b
      @current
    elseif @verbatim
      w
    else
      "<impossible> (stopped at: #{@current})"

  try: => not @blacklist[@current] and dict[@current] 

  cutoff: (s) => 
    @current = @current\sub 1, (@current\len! - s\len!)
    true

  qend: (s) =>
    q = @current\sub (@current\len! - s\len! + 1)
    q == s and q or nil

  nth: (n) =>
    s = @current\len! - n + 1
    @current\sub(s, s)

  qnth: (s, n) => s == @nth n

  add: (s) => 
    @current ..= s
    true

  inset: (s, c) =>
    for i in *s
      return true if i == c
    false

  vowel: (s) => @inset { "a", "e", "i", "o", "u", "y" }, s

  liquid: (s) => @inset { "l", "r", "s", "v", "z" }, s

  noend: (s) => @inset { "c", "g", "s", "v", "z" }, s

  qec: (s) => @qend(s) and @cutoff(s)

  exchs: (r, a) => @cutoff(r) and @add(a)

  torta: (s) => @try! or @tryadd(s)

  advly: => (not @qnth("i", 1) and @torta("le")) or @tryexch("i", "y")

  possa: =>
    if @qnth "i", 2
      @tryexch "ie", "y"
    elseif @qnth "h", 2
      @cutoff "e" unless @qnth "t", 3
      @try!
    elseif @qnth "x", 2
      @trycut "e"
    elseif @qnth("s", 2) or @qnth("z", 2)
      @cutoff "e" if @qnth("s", 3) or @qnth("z", 3)
      @try!
    elseif @qnth "v", 2
      @try! or @tryexch("ve", "fe")
    else
      @try!

  noeadde: => 
    @add "e" if @noend @nth 1
    @try!

  tryadd: (s) => @add(s) and @try!

  tryexch: (r, a) => @exchs(r, a) and @try!

  trycut: (s) => @cutoff(s) and @try!

  sufcons: =>
    if @qnth "h", 1
      (not @qnth("t", 2) and @try!) or @torta("e")
    elseif @nth(1) == @nth(2)
      (@liquid(@nth(1)) and @try!) or @trycut(@nth(1))
    elseif @vowel @nth 2
      @vowel(@nth(3)) and @noeadde! or @tryadd("e")
    else
      if @liquid @nth 1
        (@qend("rl") and @try!) or (@tryadd("e"))
      else
        @noeadde!

  sufvow: =>
    if @qec "i"
      @tryadd "y"
    elseif @qnth "y", 1
      @try!
    elseif @qnth "e", 1
      (@qnth("e", 2) and @try!) or @torta("e")
    else
      @tryadd "e"

  gensuf: =>
    snip = { "ing", "ed", "en", "er", "est" }
    for nd in *snip
      if @qec nd
        return @vowel(@nth(1)) and @sufvow! or @sufcons!

    false

  run: =>
    return @try! if @qec "n't"
    return @try! if @qec "'s"

    if @qec("'") or @qec("s")
      @qend("e") and @possa! or @try!
    else
      @qec("ly") and @advly! or @gensuf!


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
  "someone's"
  "someones"
  "someones'"
  "pleased"
  "robbed"
  "gunned"
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
