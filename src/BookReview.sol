// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Test.sol";

contract BookReview {
    event CreateReview(address user, uint256 bookId);

    address public manager;
    uint256 public reviewCount;

    struct Review {
        uint256 bookId;
        address user;
        uint256 postTime;
        string review;
        uint256 reviewId;
    }

    struct UserReview {
        uint256 bookId;
        address user;
        uint256 postTime;
        string review;
        uint256 reviewId;
        Book bookInfo;
    }

    struct BookWorm {
        address userAddr;
        string name;
        uint256 totalReviewAmount;
        Review[] userReviewList;
    }

    struct Book {
        uint256 bookId;
        uint256 totalReviewAmount;
        Review[] reviewList;
        string photoURL;
        string author;
        string name;
        string manufacture;
        string productGuid;
    }

    mapping(address => BookWorm) public user;
    mapping(uint256 => Book) public book;
    mapping(address => Review[]) public userReviews;
    mapping(uint256 => Review[]) public bookReviews;

    // 記錄某 reviewId 在 userReviews 列表中的 index。
    mapping(uint256 => uint256) public userReviewIndex;

    // 記錄某 reviewId 在 bookReviews 列表中的 index。
    mapping(uint256 => uint256) public bookReviewIndex;

    // Book id review id
    mapping(uint256 => mapping(uint256 => Review)) public bookReview;

    constructor() {
        manager = msg.sender;
    }

    function createBookInfo(
        uint256 bookId,
        string memory photoURL,
        string memory author,
        string memory name,
        string memory manufacture,
        string memory productGuid
    ) public {
        book[bookId].photoURL = photoURL;
        book[bookId].author = author;
        book[bookId].name = name;
        book[bookId].manufacture = manufacture;
        book[bookId].productGuid = productGuid;
    }

    function creatReview(uint256 bookId, string memory reviewContent) public {
        reviewCount++;
        Review memory review = Review({
            bookId: bookId,
            user: msg.sender,
            postTime: block.timestamp,
            review: reviewContent,
            reviewId: reviewCount
        });

        bookReviews[bookId].push(review);
        userReviews[msg.sender].push(review);

        // update index for to owned，轉移的 tokenId 會在 to _owned 陣列的最後一個 index
        userReviewIndex[reviewCount] = userReviews[msg.sender].length - 1;
        bookReviewIndex[reviewCount] = bookReviews[bookId].length - 1;

        bookReview[bookId][reviewCount] = review;

        emit CreateReview(msg.sender, bookId);
    }

    function editReview(uint256 bookId, uint256 reviewId, string memory reviewContent) public {
        bookReviews[bookId][bookReviewIndex[reviewCount]].review = reviewContent;
        userReviews[msg.sender][userReviewIndex[reviewCount]].review = reviewContent;
        bookReview[bookId][reviewId].review = reviewContent;
    }

    // delete
    function deleteReview(uint256 bookId, uint256 reviewId) public {
        delete bookReviews[bookId][bookReviewIndex[reviewId]];
        delete userReviews[msg.sender][userReviewIndex[reviewId]];
        delete bookReview[bookId][reviewId];

        delete bookReviewIndex[reviewId];
        delete userReviewIndex[reviewId];
    }

    // user page

    function getBookReviews(uint256 bookId) public view returns (Review[] memory) {
        return bookReviews[bookId];
    }

    function getUserReviews(address userAddr) public view returns (UserReview[] memory reviews) {
        reviews = new UserReview[](userReviews[userAddr].length);
        for (uint256 i = 0; i < userReviews[userAddr].length; i++) {
            reviews[i].bookId = userReviews[userAddr][i].bookId;
            reviews[i].user = userReviews[userAddr][i].user;
            reviews[i].postTime = userReviews[userAddr][i].postTime;
            reviews[i].review = userReviews[userAddr][i].review;
            reviews[i].reviewId = userReviews[userAddr][i].reviewId;
            reviews[i].bookInfo = book[userReviews[userAddr][i].bookId];
        }
    }
}
