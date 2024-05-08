import Link from "next/link";
import { useState, useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";

import { ConnectWallet, useAddress } from "@thirdweb-dev/react";

import { useTheme } from "next-themes";
import { Moon, Sun } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  ResizableHandle,
  ResizablePanel,
  ResizablePanelGroup,
} from "@/components/ui/resizable";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

import { searchBook } from "../api/api";

export default function Layout({ children }) {
  const { setTheme } = useTheme();

  const pathname = usePathname();
  const router = useRouter();

  const address = useAddress();

  const [search, setSearch] = useState("");

  const { data, refetch } = useQuery(
    ["searchBook", search],
    () => searchBook(search),
    {
      enabled: false,
    }
  );

  const handleSearch = async () => {
    await refetch();
  };

  const handleKeyDown = (event) => {
    if (event.key === "Enter") {
      handleSearch();
    }
  };

  useEffect(() => {
    if (data && data[0].id) {
      router.push(`/book/${data[0].id}`);
    }
  }, [data]);

  return (
    <>
      <div className="flex justify-between items-center">
        <Link href={`/book`}>
          <div className="ml-8">BOOK WORM LAND</div>
        </Link>
        <div className="flex justify-end items-center p-4">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button
                variant="outline"
                size="icon"
                style={{ height: "50px", width: "50px" }}
              >
                <Sun className="h-10 w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
                <Moon className="absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
                <span className="sr-only">Toggle theme</span>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem
                onClick={() => {
                  setTheme("light");
                }}
              >
                Light
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setTheme("dark")}>
                Dark
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setTheme("system")}>
                System
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <div className="ml-6">
            <ConnectWallet style={{ height: "50px", minWidth: "80px" }} />
          </div>

          <Link href={`/user/${address}`}>
            <Avatar className="ml-8 mr-4">
              <AvatarImage src="https://github.com/shadcn.png" alt="@shadcn" />
              <AvatarFallback>CN</AvatarFallback>
            </Avatar>
          </Link>
        </div>
      </div>

      {pathname === "/book" ? (
        <div className="flex h-svh w-full items-center justify-center p-6">
          <div className="w-6/12 flex flex-col">
            <Input
              type="text"
              placeholder="搜尋一本書"
              className="focus-visible:ring-0 h-16 mb-4 bg-white	"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onEnter={(e) => setSearch(e.target.value)}
            />
            <Button onClick={() => handleSearch()} onKeyDown={handleKeyDown}>
              Search
            </Button>
          </div>
        </div>
      ) : (
        <main>
          <ResizablePanelGroup
            direction="horizontal"
            className="h-screen rounded-lg border"
            style={{ height: "100vh" }}
          >
            <ResizablePanel defaultSize={20}>
              <div className="h-full max-w-md items-center justify-center p-6">
                <div className="flex">
                  <Input
                    type="text"
                    placeholder="search"
                    className="focus-visible:ring-0"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    onEnter={(e) => setSearch(e.target.value)}
                  />
                  <Button
                    variant="outline"
                    onClick={() => handleSearch()}
                    onKeyDown={handleKeyDown}
                  >
                    Search
                  </Button>
                </div>
                <ScrollArea className="h-full w-full mt-8 mb-8">
                  {data?.map(
                    (
                      {
                        fields: {
                          product_photo_url,
                          name,
                          author,
                          manufacturer,
                        },
                        id,
                      },
                      idx
                    ) => {
                      return (
                        <Link href={`/book/${id}`} key={idx}>
                          <div className="mb-8">
                            <img
                              src={"https://s.eslite.com" + product_photo_url}
                            ></img>
                            <p className="font-medium text-center tracking-wide my-4 text-sm		">
                              {name}
                            </p>

                            <Badge variant="secondary" className="">
                              {author}
                            </Badge>
                            <Badge variant="secondary" className="">
                              {manufacturer[0]}
                            </Badge>
                          </div>
                        </Link>
                      );
                    }
                  )}
                </ScrollArea>
              </div>
            </ResizablePanel>
            <ResizableHandle withHandle />
            <ResizablePanel defaultSize={80}>
              <ScrollArea className="h-full w-full mt-8 mb-8">
                <div className="h-full items-center justify-center p-6">
                  {children}
                </div>
              </ScrollArea>
            </ResizablePanel>
          </ResizablePanelGroup>
        </main>
      )}
    </>
  );
}
