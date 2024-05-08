import React from "react";
import { useRouter } from "next/router";

import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

function BookInfo({ data }) {
  const router = useRouter();
  return (
    <>
      <div>
        <p>Id: {router.query.slug}</p>
        {/* <img src={data?.photos[0]?.large_path}></img> */}
        <h3>書名：{data?.name}</h3>
        <p>作者：{data?.author}</p>
        <p>出版社：{data?.supplier}</p>
      </div>
      <Accordion type="single" collapsible className="w-full mb-6">
        {data?.descriptions?.map(({ name, description }, idx) => {
          return (
            <AccordionItem value="item-1" key={idx}>
              <AccordionTrigger>{name}</AccordionTrigger>
              <AccordionContent>
                <div
                  dangerouslySetInnerHTML={{
                    __html: `${description}`,
                  }}
                ></div>
              </AccordionContent>
            </AccordionItem>
          );
        })}
      </Accordion>
    </>
  );
}

export default BookInfo;
