// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/ThalesPoints.sol";
import "../src/demos/Boombox/Boombox.sol";

// TODO: Test when artists chooses how much to withdraw
// TODO: Test tier percentage changes
contract BoomboxTest is Test {
    ThalesPoints private thalesPoints;
    Boombox private boombox;
    address private admin;
    address private artist;
    string private artistId;
    string private artistId2;
    address private user1;
    address private user2;
    address private user3;
    address private artistWallet;

    // Runs before each test function, resetting the state of the contracts.
    function setUp() public {
        admin = address(this);
        artist = address(0xAAA);
        artistId = "artistId";
        artistId2 = "artistId2";
        user1 = address(0x111);
        user2 = address(0x222);
        user3 = address(0x333);
        artistWallet = address(0xaaa);

        thalesPoints = new ThalesPoints("Test Points", admin); // Thales points is the points system
        boombox = new Boombox(10, address(thalesPoints), 10, admin);
        thalesPoints.addAdmin(admin);
        thalesPoints.addSupportedContract(address(boombox));

        // Set initial points for users
        thalesPoints.addPoints(user1, 500000000);
        thalesPoints.addPoints(user2, 600000000);
        thalesPoints.addPoints(user3, 700000000);

        // Set the tier costs
        // boombox.setTierCost(artistId, uint(Boombox.Tier.Bronze, 100);
        // boombox.setTierCost(artistId, Boombox.Tier.Silver, 200);
        // boombox.setTierCost(artistId, Boombox.Tier.Gold, 300);
        // boombox.setTierCost(artistId, Boombox.Tier.Platinum, 400);
        // boombox.setTierCost(artistId, Boombox.Tier.Diamond, 500);

        // // Set the tier percentages
        // boombox.setTierPercentage(artistId, Boombox.Tier.Bronze, 10);
        // boombox.setTierPercentage(artistId, Boombox.Tier.Silver, 20);
        // boombox.setTierPercentage(artistId, Boombox.Tier.Gold, 30);
        // boombox.setTierPercentage(artistId, Boombox.Tier.Platinum, 40);
        // boombox.setTierPercentage(artistId, Boombox.Tier.Diamond, 50);
    }

    // Test signing an artist with a tier.
    function test_SignArtist() public {
        // User1 signs the artist with Bronze tier.
        vm.prank(admin);
        boombox.signArtist(artistId, user1, 50000000);

        // Check that total points have been incremented.
        assertEq(boombox.totalPoints(artistId), 50000000);
        console.log("Total points: %s", boombox.totalPoints(artistId));
        console.log(
            "User tier: %s",
            uint(boombox.participantTier(artistId, user1))
        );

        assertEq(
            uint(boombox.participantTier(artistId, user1)),
            uint(Boombox.Tier.None)
        );
        // Check that the artist points bank is updated.
        assertEq(boombox.artistPointsBank(artistId), 5000000);
        assertEq(thalesPoints.pointAllocations(artistWallet), 0);
        boombox.withdrawToArtist(artistId, artistWallet, 5000000);
        assertEq(boombox.artistPointsBank(artistId), 0);
        assertEq(thalesPoints.pointAllocations(artistWallet), 5000000);

        boombox.signArtist(artistId2, user2, 50000000);
        assertEq(boombox.totalPoints(artistId2), 50000000);
        assertEq(
            uint(boombox.participantTier(artistId2, user2)),
            uint(Boombox.Tier.None)
        );
        // Check that the artist points bank is updated.
        assertEq(boombox.artistPointsBank(artistId2), 5000000);
        assertEq(boombox.participantIndex(artistId2, user2), 1);

        assertEq(boombox.participantsByIndex(artistId2, 1), user2);
        assertEq(boombox.participants(artistId2, 0), user2);

        boombox.resetArtist(artistId2);
        assertEq(boombox.participantIndex(artistId2, user2), 0);

        console.log("HEREEE");
        console.log(boombox.participantIndex(artistId2, user2));
        assertEq(boombox.totalPoints(artistId2), 0);
        assertEq(
            uint(boombox.participantTier(artistId2, user2)),
            uint(Boombox.Tier.None)
        );
        assertEq(uint(boombox.participantIndex(artistId2, user2)), 0);

        // Check that the artist points bank is updated.
        assertEq(boombox.artistPointsBank(artistId2), 0);
        assertEq(boombox.totalPoints(artistId), 50000000);
        assertEq(boombox.participantsByIndex(artistId, 1), user1);
    }

    // Test the distribution of rewards.
    function test_DistributeRewards() public {
        // Set up some participants with different tiers
        vm.prank(admin);
        boombox.signArtist(artistId, user1, 50000000);
        vm.prank(admin);
        boombox.signArtist(artistId, user2, 50000000);
        vm.prank(admin);
        boombox.signArtist(artistId, user3, 50000000);
        boombox.upgradeUserTier(artistId, user3, Boombox.Tier.Platinum);

        uint user1PointsBefore = thalesPoints.pointAllocations(user1);
        uint user2PointsBefore = thalesPoints.pointAllocations(user2);
        uint user3PointsBefore = thalesPoints.pointAllocations(user3);

        uint totalPointsBefore = boombox.totalPoints(artistId);
        // Check that the total points equals the points to distribute.
        //        assertEq(boombox.totalPoints(), boombox.pointsToDistribute());
        assertEq(boombox.pointsToDistribute(artistId), 135000000);

        // Distribute rewards
        vm.prank(admin);
        console.log("About to distribute");
        assertEq(boombox.pointsAwardedByArtist(artistId, user1), 0);
        boombox.distribute(artistId);
        assertEq(boombox.pointsAwardedByArtist(artistId, user1), 36000000);

        // Check that the points to distribute is reset to 0
        assertEq(boombox.pointsToDistribute(artistId), 0);
        // Check that the totalPoints is the same.
        //        assertEq(boombox.totalPoints(), totalPointsBefore);

        uint user1PointsAfter = thalesPoints.pointAllocations(user1);
        uint user2PointsAfter = thalesPoints.pointAllocations(user2);
        uint user3PointsAfter = thalesPoints.pointAllocations(user3);

        console.log(
            "User1 points: %s vs %s",
            user1PointsBefore,
            user1PointsAfter
        );
        console.log(
            "User 1 points difference: %s",
            user1PointsAfter - user1PointsBefore
        );
        console.log(
            "User2 points: %s vs %s",
            user2PointsBefore,
            user2PointsAfter
        );
        console.log(
            "User 2 points difference: %s",
            user2PointsAfter - user2PointsBefore
        );
        console.log(
            "User3 points: %s vs %s",
            user3PointsBefore,
            user3PointsAfter
        );
        console.log(
            "User 3 points difference: %s",
            user3PointsAfter - user3PointsBefore
        );

        // Now run this test with 10000 users.
        // for (uint i = 0; i < 10000; i++) {
        //     address user = vm.addr(i + 1);
        //     // Give some points to the user.
        //     thalesPoints.addPoints(user, 100);
        //     vm.prank(user);
        //     boombox.signArtist(artistId, user, uint(Boombox.Tier.Bronze));
        // }
        // console.log(
        //     "points to distribute: %s",
        //     boombox.pointsToDistribute(artistId)
        // );
        // console.log(
        //     "user 100 points before distribution: %s",
        //     thalesPoints.pointAllocations(vm.addr(100))
        // );
        // console.log(
        //     "user 1000 points before distribution: %s",
        //     thalesPoints.pointAllocations(vm.addr(1000))
        // );
        // vm.prank(admin);
        // boombox.distribute(artistId);
        // console.log(
        //     "points to distribute after distribution: %s",
        //     boombox.pointsToDistribute(artistId)
        // );
        // // Sample some users and check that their points have increased.
        // console.log(
        //     "User1 points: %s vs %s",
        //     user1PointsBefore,
        //     thalesPoints.pointAllocations(user1)
        // );
        // console.log(
        //     "User2 points: %s vs %s",
        //     user2PointsBefore,
        //     thalesPoints.pointAllocations(user2)
        // );
        // console.log(
        //     "User3 points: %s vs %s",
        //     user3PointsBefore,
        //     thalesPoints.pointAllocations(user3)
        // );
        // console.log(
        //     "User 100 points after distribution: %s",
        //     thalesPoints.pointAllocations(vm.addr(100))
        // );
        // console.log(
        //     "User 1000 points after distribution: %s",
        //     thalesPoints.pointAllocations(vm.addr(1000))
        // );
        // console.log(
        //     "User 10000 points after distribution: %s",
        //     thalesPoints.pointAllocations(vm.addr(10000))
        // );

        // // Check if points are distributed correctly to the first three users
        // assertEq(
        //     thalesPoints.pointAllocations(user1),
        //     user1PointsBefore + user1Points
        // );
        // assertEq(
        //     thalesPoints.pointAllocations(user2),
        //     user2PointsBefore + user2Points
        // );
        // assertEq(
        //     thalesPoints.pointAllocations(user3),
        //     user3PointsBefore + user3Points
        // );
    }
    //
    //    // Test that users cannot sign with a tier if they don't have enough points.
    //    function test_SignArtist_NotEnoughPoints() public {
    //        thalesPoints.setPoints(user1, 10); // Set low points for user1
    //        vm.prank(user1);
    //        vm.expectRevert("Not enough points");
    //        boombox.signArtist(user1, Boombox.Tier.Platinum);
    //    }
    //
    //    // Test pagination in distributeStartEnd function.
    //    function test_DistributionPagination() public {
    //        // TODO.
    //    }
}
