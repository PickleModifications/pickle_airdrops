import { AppControls, DisplayCurrency, GetItemImage, GetItemLabel } from "@/App";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { LockIcon } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import classes from "./AirdropContainer.module.css";

export type Item = {
    label?: string;
    image?: string;
    name: string;
    count: number;
}

export type AirdropContainerItem = Item & {
    itemType?: string;
    captureTime: number;
};

export type Vector2D = {
    x: number;
    y: number;
}

type AirdropContainerInfo = {
    position: Vector2D;
    scale: number;
    image: string;
    label: string;
    unlockTime: number;
    description: string;
    maxSlots: number;
    items: AirdropContainerItem[];
};

function GetCountdownText(seconds: number) {
    // use 00:00 format
    const minutes = Math.floor(seconds / 60);
    const secondsLeft = seconds % 60;
    return `${minutes.toString().padStart(2, "0")}:${secondsLeft.toString().padStart(2, "0")}`;
}

function AirdropContainer({ containerInfo }: { containerInfo: AirdropContainerInfo }) {
    const { config } = useConfig();
    const [captureInfo, setCaptureInfo] = useState<{ slot: number; timeLeft: number, success?: boolean } | null>(null);
    const [items, setItems] = useState<AirdropContainerItem[]>(containerInfo.items);
    useEffect(() => {
        if (captureInfo) {
            const interval = setInterval(() => {
                setCaptureInfo((prev) => {
                    if (!prev) return null;
                    if (prev.timeLeft <= -100) {
                        clearInterval(interval);
                        fetchNui("updateAirdropContainerItemStatus", { slot: prev.slot + 1 });
                        return null;
                    }
                    if (prev.timeLeft <= 0 && !prev.success) {
                        fetchNui("takeAirdropContainerItem", { slot: prev.slot + 1 });
                        return { ...prev, timeLeft: prev.timeLeft - 100, success: true };
                    }
                    return { ...prev, timeLeft: prev.timeLeft - 100 };
                });
            }, 100);
            return () => clearInterval(interval);
        }
    }, [captureInfo]);
    useNuiEvent("updateAirdropContainerItems", (data: any) => {
        setItems(data.items);
    });
    return (
        <div className='flex flex-col absolute px-4 py-4 gap-4 rounded-md top-[50%] left-[50%] translate-x-[-50%] translate-y-[-50%] select-none' style={{
            transition: "opacity 0.25s ease-in-out",
        }}>
            <div className="grid grid-cols-5 gap-2 items-center">
                {Array.from({ length: Math.ceil(containerInfo.maxSlots / 5) * 5 }).map((_, index) => {
                    const item = items[index];
                    if (!item) {
                        return index + 1 > containerInfo.maxSlots ? (
                            <div key={index} className="w-24 h-24 bg-background/75 rounded-md flex items-center justify-center">
                                <LockIcon size={24} className="text-zinc-400" />
                            </div>
                        ) : (
                            <div key={index} className="w-24 h-24 bg-background/50 rounded-md flex items-center justify-center">
                                
                            </div>
                        );
                    }
                    return (
                        <div key={index} className="relative w-24 h-24 bg-background/50 rounded-md overflow-hidden flex flex-col gap-0 items-center justify-between cursor-pointer hover:scale-105 transition-transform duration-200 ease-in-out" onMouseDown={(e) => {
                            if (captureInfo) return;
                            if (e.button !== 0) return;
                            setCaptureInfo({ slot: index, timeLeft: item.captureTime * 1000 });
                            fetchNui("updateAirdropContainerItemStatus", { slot: index + 1, status: "capturing" });
                        }} onMouseUp={(e) => {
                            if (!captureInfo) return;
                            if (e.button !== 0) return;
                            fetchNui("updateAirdropContainerItemStatus", { slot: index + 1 });
                            setCaptureInfo(null);
                        }} onMouseLeave={(e) => {
                            if (!captureInfo) return;
                            if (e.button !== 0) return;
                            fetchNui("updateAirdropContainerItemStatus", { slot: index + 1 });
                            setCaptureInfo(null);
                        }}>
                            <div className="w-full z-10 px-[4px] py-[2px] flex justify-end">
                                <div className="font-semibold text-xs">
                                    {(item.itemType && (item.itemType == "money" || item.itemType == "dirty_money")) ? (
                                        <DisplayCurrency value={item.count} />
                                    ) : (
                                        <>x{item.count}</>
                                    )}
                                </div>
                            </div>
                            {item.image ? (
                                <img src={item.image} alt={""} className="p-[10px] max-h-14" draggable={false} onError={(e) => {
                                    const target = e.target as HTMLImageElement;
                                    target.style.display = "none"; // hides the image
                                }} />  
                            ) : (
                                <img src={GetItemImage(item.name)} alt={""} className="w-14 h-14" draggable={false} onError={(e) => {
                                    const target = e.target as HTMLImageElement;
                                    target.style.display = "none"; // hides the image
                                }} />                            
                            )}
                            <div className="w-full z-10 px-[4px] py-[2px] bg-background/50">
                                <div className="font-semibold text-xs text-center truncate">
                                    {item.label ? (
                                        item.label
                                    ) : (
                                        <GetItemLabel item={(item.name || item.itemType) as string} />
                                    )}
                                </div>
                            </div>
                            {(captureInfo && captureInfo.slot == index) && (
                                <div className="absolute bottom-0 left-0 w-full z-10" style={{
                                    background: "white",
                                    opacity: 0.2,
                                    height: Math.min(100 - Math.ceil(captureInfo.timeLeft / (item.captureTime * 1000) * 100), 100) + "%",
                                    transition: "height 0.1s ease-in-out",
                                }}>
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>
            <div className="font-semibold text-sm text-center">
                <Translate id="airdrop_container_desc" />
            </div>
        </div>
    )
}

function AirdropContainerHUD() {
    const [airdropContainer, setAirdropContainer] = useState<any | null>(null);
    const position: Vector2D = (airdropContainer ? airdropContainer.position : {x: 0, y: 0});
    const scale: number = (airdropContainer ? airdropContainer.scale : 0.0);

    useNuiEvent("updateAirdropContainerHUD", (data) => {
        if (!data || !data.container) {
            setAirdropContainer(null);
            return;
        }
        setAirdropContainer({
            ...data.container,
            position: {
                x: data.container.position.x * window.innerWidth,
                y: data.container.position.y * window.innerHeight,
            },
            scale: data.container.scale,
        });
    });
    return (
        <div style={{position: "absolute", top: 0, left: 0, overflow: "hidden", width: "100vw", height: "100vh", pointerEvents: "none"}}>
            {airdropContainer && (
                <div className={classes.lootContainer} style={{left: position.x, top: position.y, transformOrigin: "0% 100%", transform: "scale(" + scale + ")", position: "absolute", display: "flex", flexDirection: "column", gap: "0px", backgroundColor: "#1E1E1E", borderRadius: "6px", border: "1px solid #27272A"}}>
                    <div className={classes.lootInfo} style={{position: "relative", display:"flex", padding: "6px"}}>
                        <img src={airdropContainer.image} alt="loot" style={{position: "absolute", bottom: 12, left: 12, width: "75px"}}/>
                        <div style={{display:"flex", height: "100%", alignItems: "flex-end"}}>
                            <div style={{display:"flex", marginLeft: 87, paddingTop: 10, flexDirection: "column", gap: "0px", padding: "0px 6px"}}>
                                <div style={{display:"flex", gap: "6px", alignItems: "center"}}>
                                <div className="font-semibold text-lg text-white">{airdropContainer.label}</div>
                                </div>
                                <div className="font-semibold text-sm text-zinc-400">{airdropContainer.description}</div>
                            </div>
                        </div>
                    </div>
                    <div className={classes.lootControls} style={{gap: "6px", display:"flex", alignItems: "center", padding: "6px 12px", borderTop: "1px solid #27272A"}}>
                            {airdropContainer.unlockTime > 0 ? (
                                <div className="font-semibold text-sm text-zinc-400">
                                    <Translate id="airdrop_container_unlock_time" args={[GetCountdownText(airdropContainer.unlockTime)]} />
                                </div>
                            ) : (
                                <>
                                    <div className="relative w-6 h-6 bg-white text-black rounded-sm flex items-center justify-center" style={{
                                        filter: (scale < 1 ? "brightness(0.5)" : "brightness(1)"),
                                    }}>
                                        <div className="font-bold text-sm absolute top-[50%] left-[50%] z-1" style={{transform: "translate(-50%, -50%)"}}>
                                            E
                                        </div>
                                    </div>
                                    <div className="font-bold text-xl">
                                        <Translate id="airdrop_interact" />
                                    </div>
                                </>
                            )}
                    </div>
                </div>
            )}
        </div>
    )
}

export default function AirdropContainerInterface() {
    const [showing, setShowing] = useState(false);
    const [containerInfo, setContainerInfo] = useState<AirdropContainerInfo | null>(
        null
    );
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (!containerInfo) return;
            if (event.key === "Escape" || event.key === "Backspace") {
                fetchNui("exitInterface", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    useNuiEvent("setContainerInfo", (data: any) => {
        if (data.containerInfo) {
            setShowing(true);
            setContainerInfo(data.containerInfo);
        }
        else {
            setShowing(false);
            setTimeout(() => {
                setContainerInfo(null);
            }, 300);
        }
    });
    return (
        <>
            <div className="absolute bottom-0 left-0 w-screen h-screen" style={{
                opacity: showing ? 1 : 0,
                transition: "opacity 0.25s ease-in-out",
            }}>
                {containerInfo && (
                    <>
                        <AirdropContainer containerInfo={containerInfo} />
                        <AppControls />
                    </>
                )}
            </div>
            <AirdropContainerHUD/>
        </>
    )
}
