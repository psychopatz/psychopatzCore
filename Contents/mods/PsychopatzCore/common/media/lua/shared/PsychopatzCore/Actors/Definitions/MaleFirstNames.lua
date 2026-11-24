-- Pure data definition: male first names and embedded authored nicknames for PsychopatzCore.
-- Bare strings have no authored nicknames; keyed tables map Forename = { "Nick1", ... }.
-- Managed via the pz-name-definitions skill harness (do not mix logic here).

return {
    -- A
    "Aaron",
    Abraham = { "Abe" },
    "Adam",
    Albert = { "Al", "Bert" },
    Alex = { "Al", "Lex" },
    Alexander = { "Alex", "Xander" },
    Andrew = { "Andy", "Drew" },
    Anthony = { "Tony" },
    Arthur = { "Art", "Artie" },

    -- B
    "Ben",
    Benjamin = { "Ben", "Benny" },
    Bernard = { "Bernie" },
    Bradley = { "Brad" },

    -- C
    "Caleb",
    Cameron = { "Cam" },
    Charles = { "Charlie", "Chuck" },
    Christopher = { "Chris", "Topher" },
    Clifford = { "Cliff" },

    -- D
    Daniel = { "Dan", "Danny" },
    David = { "Dave", "Davey" },
    "Derek",
    Donald = { "Don", "Donny" },
    Douglas = { "Doug" },

    -- E
    Edward = { "Ed", "Eddie", "Ted" },
    "Eli",
    Eugene = { "Gene" },

    -- F
    "Felix",
    Francis = { "Frank", "Frankie" },
    Franklin = { "Frank", "Frankie" },
    Frederick = { "Fred", "Freddy" },

    -- G
    Gabriel = { "Gabe" },
    Gerald = { "Gerry", "Jerry" },
    "Grant",
    Gregory = { "Greg" },

    -- H
    Harold = { "Hal", "Harry" },
    Harrison = { "Harry" },
    "Harvey",
    Henry = { "Hank", "Harry" },
    Howard = { "Howie" },

    -- I
    "Isaac",

    -- J
    Jacob = { "Jake" },
    James = { "Jim", "Jimmy", "Jamie" },
    Jeremy = { "Jem" },
    "Jonah",
    Jonathan = { "Jon", "Jonny" },
    Jordan = { "Jordy" },
    Joseph = { "Joe", "Joey" },
    Joshua = { "Josh" },

    -- K
    Kenneth = { "Ken", "Kenny" },

    -- L
    Lawrence = { "Larry" },
    Leonard = { "Leo", "Lenny" },
    "Liam",

    -- M
    "Marcus",
    Martin = { "Marty" },
    Matthew = { "Matt", "Matty" },
    Michael = { "Mike", "Mikey" },

    -- N
    Nathan = { "Nate" },
    Nathaniel = { "Nate", "Nathan" },
    Nicholas = { "Nick", "Nicky" },
    "Noah",

    -- O
    Oliver = { "Ollie" },
    "Owen",

    -- P
    Patrick = { "Pat", "Paddy", "Rick" },
    Peter = { "Pete" },
    Philip = { "Phil" },
    Phillip = { "Phil" },

    -- Q
    "Quinn",

    -- R
    Raymond = { "Ray" },
    Richard = { "Rich", "Rick", "Ricky" },
    Robert = { "Rob", "Robbie", "Bob", "Bobby" },
    Ronald = { "Ron", "Ronnie" },
    "Rory",
    Russell = { "Russ" },

    -- S
    Sammie = { "Sam" },
    Samuel = { "Sam", "Sammy" },
    Sebastian = { "Seb", "Bash" },
    Stephen = { "Steve", "Stevie" },
    Steven = { "Steve", "Stevie" },

    -- T
    Taylor = { "Tay" },
    Theodore = { "Ted", "Teddy", "Theo" },
    Thomas = { "Tom", "Tommy" },
    Timothy = { "Tim", "Timmy" },

    -- V
    "Victor",
    Vincent = { "Vince", "Vinny" },

    -- W
    Walter = { "Walt", "Wally" },
    William = { "Will", "Bill", "Billy", "Liam" },

    -- Z
    Zachary = { "Zach", "Zack" },
}
