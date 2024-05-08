// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {BookReview} from "../src/BookReview.sol";

contract BookTest is Test {
    BookReview public book;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        // Fork Ethereum mainnet at block 15_941_703
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpc, 15_941_703);

        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(admin);
        book = new BookReview();
        vm.stopPrank();
    }

    function testCreateReview() public {
        string memory reviewContent = "This is a great book!";
        string memory reviewContent2 = "This is a bad book!";

        vm.startPrank(user1);
        // CREATE book id 1 reviewId 1
        book.createBookInfo(
            1,
            "https://s2.eslite.com/unsafe/fit-in/x900/s.eslite.com/upload/product/o/2681890395001/20210324065415808336.jpg",
            "a",
            "b",
            "c",
            "123"
        );
        book.creatReview(1, reviewContent);

        (,,, string memory review, uint256 reviewId) = book.bookReviews(1, 0);
        assertEq(review, reviewContent);
        assertEq(book.getBookReviews(1).length, 1);
        assertEq(book.bookReviewIndex(reviewId), 0);
        assertEq(book.userReviewIndex(reviewId), 0);

        (uint256 bookId,,,,) = book.userReviews(user1, 0);
        assertEq(bookId, 1);
        assertEq(book.getUserReviews(user1).length, 1);

        vm.stopPrank();

        vm.startPrank(user2);
        // CREATE book id 1 reviewId 2 bookReviewIndex[2]=1 userReviewIndex[2]=0
        book.creatReview(1, reviewContent2);

        (,,, review, reviewId) = book.bookReviews(1, 1);
        assertEq(review, reviewContent2);
        assertEq(book.getBookReviews(1).length, 2);
        assertEq(book.bookReviewIndex(reviewId), 1);
        assertEq(book.userReviewIndex(reviewId), 0);

        (bookId,,,,) = book.userReviews(user2, 0);

        assertEq(bookId, 1);
        assertEq(book.getUserReviews(user2).length, 1);
        assertEq(book.getUserReviews(user2)[0].bookInfo.name, "b");

        // EDIT book id 1 reviewId 2
        string memory editContent = "Edited!";

        book.editReview(1, 2, editContent);

        (,,, review,) = book.bookReviews(1, book.bookReviewIndex(reviewId)); //1
        assertEq(review, editContent);

        (bookId,,, review,) = book.userReviews(user2, book.userReviewIndex(reviewId)); //0
        assertEq(review, editContent);

        (bookId,,, review,) = book.bookReview(1, reviewId);
        assertEq(review, editContent);

        // DELETE
        book.deleteReview(1, reviewId);

        (,,, review, reviewId) = book.bookReviews(1, book.bookReviewIndex(reviewId)); //1

        (bookId,,, review,) = book.userReviews(user2, book.userReviewIndex(reviewId)); //0
        assertEq(review, "");

        (bookId,,, review,) = book.bookReview(1, reviewId);
        // assertEq(review, "");

        vm.stopPrank();
    }
}
