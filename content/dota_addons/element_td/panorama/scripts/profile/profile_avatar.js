var Container = $("#AvatarBestBadges")
var maxBadges = 6

function CreateAvatarBadges() {
    Container.RemoveClass("Hide")

    // Loop over the badges

    // Decide the best badges to show and put them on a list

    // Iterate this list calling CreateBadges

    GameUI.CreateBadges(Container, GameUI.FormatVersion("1.3"), 1, 0, 0, 0)
    GameUI.CreateBadges(Container, GameUI.FormatVersion("1.2"), 0, 0, 3, 81)
    GameUI.CreateBadges(Container, GameUI.FormatVersion("1.1"), 0, 0, 30, 42)
    GameUI.CreateBadges(Container, GameUI.FormatVersion("1.0"), 30, 25, 0, 0)
}

CreateAvatarBadges()

/*
Load Wins and Ranks
$("#GamesWon")
$("#ClassicRank")
$("#ExpressRank")
*/