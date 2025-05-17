import { GetItemImage } from "@/App";
import { useConfig } from "@/providers/config";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { useEffect, useRef, useState } from "react";

export type CookingComponent = any;

type CookingInfo = {
    restaurantId: number;
    entityId: string;
}

function CookingDisplay({ cookingInfo }: { cookingInfo: CookingInfo }) {
    const { config } = useConfig();
    const [currentCategory, setCurrentCategory] = useState<string>("All Components");
    const categoryOrder = ["All Components"]
    const [isDragging, setIsDragging] = useState(false);
    let generatedCategories: string[] = [];
    Object.entries(config.cookingComponents).forEach(([componentId, component]) => {
        if (component.categories) {
            component.categories.forEach((category: string) => {
                if (!generatedCategories.includes(category)) {
                    generatedCategories.push(category);
                }
            });
        }
    });
    generatedCategories.sort();
    generatedCategories.forEach((category) => {
        categoryOrder.push(category);
    });

    const scrollableRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const scrollableDiv = scrollableRef.current;
        if (scrollableDiv) {
            const handleWheel = (event: WheelEvent) => {
                event.preventDefault();
                scrollableDiv.scrollLeft += event.deltaY;
            };

            scrollableDiv.addEventListener('wheel', handleWheel, { passive: false });

            return () => {
                scrollableDiv.removeEventListener('wheel', handleWheel);
            };
        }
    }, []);

    return (
        <div className='flex flex-row bg-background/95 absolute px-4 py-4 gap-4 rounded-md' style={{
            width: "calc(100% - 80px)",
            height: "200px",
            bottom: "40px",
            left: '40px',
            transition: "opacity 0.25s ease-in-out",
        }}>
            <div className="px-2 py-2 bg-background/95 rounded-md">
                <div className="flex flex-col overflow-auto h-full w-full wrap-none pr-2">
                    {categoryOrder.map((category) => (
                        <div className="flex flex-col gap-0 mb-1 cursor-pointer hover:text-zinc-400" key={category} onClick={() => setCurrentCategory(category)}>
                            <div className="text-md text-nowrap">{category}</div>
                            <div className="h-[2px] bg-white" style={{
                                width: currentCategory === category ? "100%" : 0,
                                transition: "width 0.25s ease-in-out",
                            }} />
                        </div>
                    ))}
                </div>
            </div>
            <div ref={scrollableRef} className="flex flex-row gap-2 p-4 bg-background/95 w-full rounded-md overflow-x-auto">
                {Object.entries(config.cookingComponents).map(([componentId, component]) => {
                    if (currentCategory !== "All Components" && component.categories && !component.categories.includes(currentCategory)) {
                        return null;
                    }
                    return (
                        <div key={componentId} draggable={true} className="flex aspect-square select-none drag-none flex-col items-center justify-center bg-secondary/50 rounded-md p-2 cursor-grab ratio-1" 
                        onDragStart={(e) => {
                            e.dataTransfer.effectAllowed = 'move';
                            e.currentTarget.style.cursor = 'grabbing';
                            fetchNui("setCookingComponent", {
                                componentId: componentId
                            });
                        }}
                        onDragEnd={(e) => {
                            e.currentTarget.style.cursor = 'grab';
                            fetchNui("setCookingComponent");
                        }}
                        style={{
                        }}>
                            <img src={GetItemImage(componentId)} alt={componentId} className="w-full h-full object-cover rounded-md" draggable={false}/>
                        </div>
                    )
                })}
            </div>
        </div>
    )
}

export default function CookingInterface() {
    const [cookingInfo, setCookingInfo] = useState<CookingInfo | null>({
        restaurantId: 0,
        entityId: "",
    });
    useNuiEvent("setCookingInfo", (data: any) => {
        setCookingInfo(data.cookingInfo);
    });
    return (
        <div className="absolute bottom-0 left-0 w-screen h-screen">
            {cookingInfo && (
                <CookingDisplay cookingInfo={cookingInfo} />
            )}
        </div>
    )
}