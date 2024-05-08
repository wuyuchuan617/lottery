import { useState } from "react";
import { useRouter } from "next/router";
import { useQuery } from "@tanstack/react-query";

import {
  useContract,
  Web3Button,
  useContractRead,
  useContractWrite,
} from "@thirdweb-dev/react";

import { Textarea } from "@/components/ui/textarea";
import { Separator } from "@/components/ui/separator";

import { searchSingleBook } from "../../api/api";
import { BOOK_CONTRACT } from "../../const";
import ReviewCard from "../../components/ReviewCard";
import BookInfo from "../../components/BookInfo";

export default function BookPage() {
  const router = useRouter();

  const [review, setReview] = useState("");

  // Query
  const { data } = useQuery(["searchSingleBook", router.query.slug], () =>
    searchSingleBook(router.query.slug)
  );

  // Contract
  const { contract } = useContract(BOOK_CONTRACT);
  const { data: reviews, refetch } = useContractRead(
    contract,
    "getBookReviews",
    [data?.id]
  );
  const { mutateAsync: creatReview } = useContractWrite(
    contract,
    "creatReview"
  );
  const { mutateAsync: createBookInfo } = useContractWrite(
    contract,
    "createBookInfo"
  );

  return (
    <>
      <BookInfo data={data} />

      <Textarea
        className="mb-4 bg-[#D6D7D2]"
        placeholder="Type your message here."
        value={review}
        onChange={(e) => setReview(e.target.value)}
      />
      <div className="flex justify-end mb-8">
        <Web3Button
          style={{ backgroundColor: "#282828", color: "white" }}
          contractAddress={BOOK_CONTRACT}
          action={async () => {
            if (
              reviews?.filter(
                (item) =>
                  item.user !== "0x0000000000000000000000000000000000000000"
              )?.length === 0
            ) {
              
              await createBookInfo({
                args: [
         
                  Number(data.id),
                  data.photos[0]?.large_path,
                  data.author,
                  data.name,
                  data.supplier,
                  router.query.slug,
                ],
              });
            }
            await creatReview({ args: [Number(data.id), review] });
            setReview("");
            refetch();
          }}
        >
          Submit Review
        </Web3Button>
      </div>

      <Separator className="my-8 mt-4" />

      {reviews?.map((item, idx) => {
        return <ReviewCard data={item} isUserPage={false} key={idx}/>;
      })}
    </>
  );
}
