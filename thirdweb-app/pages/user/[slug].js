import { useState } from "react";
import { useRouter } from "next/router";

import {
  useAddress,
  useContract,
  Web3Button,
  useContractRead,
  useContractWrite,
} from "@thirdweb-dev/react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

import ReviewCard from "../../components/ReviewCard";
import { BOOK_CONTRACT } from "../../const";

export default function BookPage() {
  const router = useRouter();

  const address = useAddress();

  const { contract } = useContract(BOOK_CONTRACT);
  const { data: reviews, isLoading } = useContractRead(
    contract,
    "getUserReviews",
    [router.query.slug]
  );

  return (
    <>
      <div className="flex items-center flex-col mb-8">
        <Avatar>
          <AvatarImage src="https://github.com/shadcn.png" alt="@shadcn" />
          <AvatarFallback>CN</AvatarFallback>
        </Avatar>
        <p className="mt-4">{address}</p>
      </div>

      {reviews?.map((item, idx) => {
        return <ReviewCard data={item} isUserPage={true} key={idx}/>;
      })}
    </>
  );
}
