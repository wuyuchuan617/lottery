import React, { useState } from "react";
import Link from "next/link";
import moment from "moment";

import {
  useContract,
  Web3Button,
  useContractWrite,
  useContractRead,
} from "@thirdweb-dev/react";

import { MoreHorizontal } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

import { cn } from "../lib/utils";
import { BOOK_CONTRACT } from "../const";

function ReviewCard({ data, isUserPage }) {
  const { review, user, postTime, reviewId, bookId, bookInfo = {} } = data;
  const { photoURL, name, productGuid } = bookInfo;

  const [editingId, setEditingId] = useState("0");
  const [editingReview, setEditingReview] = useState("");

  const { contract } = useContract(BOOK_CONTRACT);
  const { refetch } = useContractRead(contract, "getBookReviews", [bookId]);
  const { mutateAsync: editReview } = useContractWrite(contract, "editReview");
  const { mutateAsync: deleteReview } = useContractWrite(
    contract,
    "deleteReview"
  );

  if (user === "0x0000000000000000000000000000000000000000") return "";

  return (
    <>
      <button
        key={reviewId}
        className={cn(
          "w-full flex flex-col items-start gap-2 rounded-lg border p-3 text-left text-sm transition-all  bg-[#D9C7AA] mb-4"
        )}
      >
        <div className="flex justify-between w-full">
          {isUserPage && (
            <div className={isUserPage && "w-1/6 mr-6"}>
              <img src={photoURL} />
            </div>
          )}
          <div className={isUserPage ? "w-5/6" : "w-full"}>
            <div className="flex w-full flex-col gap-1">
              <div className="flex items-center">
                <div className="flex items-center gap-2">
                  {isUserPage ? (
                    <Link href={`/book/${Number(productGuid)}`}>
                      <div className="font-semibold">{name}</div>
                    </Link>
                  ) : (
                    <Link href={`/user/${user.toString()}`}>
                      <div className="font-semibold">{user.slice(0, 7)}</div>
                    </Link>
                  )}
                </div>
                <div className={cn("ml-auto text-xs")}>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" className="h-8 w-8 p-0">
                        <span className="sr-only">Open menu</span>
                        <MoreHorizontal className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem
                        onClick={() => {
                          setEditingId(reviewId);
                          setEditingReview(review);
                        }}
                      >
                        Edit
                      </DropdownMenuItem>
                      <DropdownMenuItem>
                        <Web3Button
                          contractAddress={BOOK_CONTRACT}
                          action={async () => {
                            await deleteReview({
                              args: [Number(bookId), reviewId.toString()],
                            });
                          }}
                          style={{
                            minHeight: "0",
                            minWidth: "0",
                            backgroundColor: "transparent",
                            fontSize: "14px",
                            padding: "0",
                          }}
                        >
                          Delete
                        </Web3Button>
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>
              <div className="text-xs font-medium text-muted-foreground">
                {moment(postTime).format("MMMM Do YYYY, h:mm:ss a")}
              </div>
            </div>
            <div className="line-clamp-2 text-xs font-normal w-full">
              {editingId === "0" ? (
                <p className="mt-2">{review}</p>
              ) : (
                <>
                  <Textarea
                    className="mt-4 mb-4"
                    placeholder="Type your message here."
                    value={editingReview}
                    onChange={(e) => setEditingReview(e.target.value)}
                  />

                  <div className="flex justify-end">
                    <Button variant="outline" onClick={() => setEditingId("0")}>
                      Cancel
                    </Button>

                    <Web3Button
                      contractAddress={BOOK_CONTRACT}
                      action={async () => {
                        await editReview({
                          args: [Number(bookId), reviewId, editingReview],
                        });
                        refetch();
                        setEditingId("0");
                      }}
                      style={{
                        height: "40px",
                        minHeight: "40px",
                        marginLeft: "8px",
                        fontSize: "14px",
                        fontWeight: "500",
                      }}
                    >
                      Confirm
                    </Web3Button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </button>
    </>
  );
}

export default ReviewCard;
