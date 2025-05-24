import { Translate } from "@/providers/locale/Locale"
import { useEffect, useState } from "react"
import { Button } from "../ui/button"
import { Edit, Plus, Save } from "lucide-react"
import { AppControls, DisplayCurrency } from "../../App"
import { useNuiEvent } from "@/providers/nui/useNui"
import { fetchNui } from "@/providers/nui/fetchNui"
import { useConfig } from "@/providers/config"

type GameSetting = {
    variable: string,
    type: string,
    default?: any,
    min?: number,
    max?: number,
    label: string,
    options?: {
        value: string,
        label: string,
    }[],
    placeholder?: string,
}

export type GameSettingsType = {
    [key: string]: GameSetting[]
}
        
const DEFAULT_LOCATION: Location = {
    coords: {x: 0, y: 0, z: 0},
    rotation: {x: 0, y: 0, z: 0},
}

type vector3 = {
    x: number,
    y: number,
    z: number,
}

type Location = {
    coords: vector3,
    rotation?: vector3,
}

type Player = {
    identifier: string,
    name: string,
}

type AirdropTemplateEntity = {
    id: string,
    type: string,
    location?: Location,
    settings: {
        [key: string]: any,
    },
}

type AirdropTemplate = {
    id: number,
    settings: AirdropTemplateSettings,
}

function Location({ id, info, defaultLocation, className, onUpdate }: { id?: any, info?: any, defaultLocation: Location, className?: string, onUpdate?: (location: Location) => void }) {
    const coordinates = defaultLocation.coords || {x: 0, y: 0, z: 0}
    const rotation = defaultLocation.rotation || {x: 0, y: 0, z: 0}
    useNuiEvent("setLocation", (data: any) => {
        if (!id && data.id) return;
        if (id && data.id !== id) return;
        if (onUpdate) {
            onUpdate(data.location)
        }
    })
    return (
        <div className="flex flex-row items-center gap-2">
            <div className={className}>{`vector3(${coordinates.x.toFixed(2)}, ${coordinates.y.toFixed(2)}, ${coordinates.z.toFixed(2)})`}</div>
            {onUpdate && (
                <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                    fetchNui("editLocation", {
                        id: id,
                        info: info,
                        coords: coordinates, 
                        rotation: rotation,
                    })
                    // Do cool stuff here
                }}/>
            )}
        </div>
    )
}

function Player({ info, defaultPlayer, className, onUpdate }: { info?: any, defaultPlayer?: Player, className?: string, onUpdate?: (player: Player) => void }) {
    useNuiEvent("setPlayer", (data: any) => {
        if (onUpdate) {
            onUpdate(data.player)
        }
    })
    return (
        <div className="flex flex-row items-center gap-2">
            <div className={className}>{defaultPlayer?.name || <Translate id="none"/>}</div>
            {onUpdate && (
                <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                    fetchNui("editPlayer", {
                        info: info,
                        player: defaultPlayer, 
                    })
                    // Do cool stuff here
                }}/>
            )}
        </div>
    )
}

type AirdropTemplateSettings = {
    image: string;
    label: string;
    cronSchedule: string;
    item: string;
    radius: number;
    spawnRadiusMultiplier: number;
    dropBlipEnabled: boolean;
    radiusBlipEnabled: boolean;
    dropModel: string;
    minidropModel: string;
    items: { 
        chance: 2, 
        itemType: "weapon", 
        name: "WEAPON_APPISTOL", 
        range: number[];
    }[];
    itemRange: number[];
    containers: number;
}

function AirdropTemplateDisplay({ isManager, isCreatingEntity, defaultEntityType, entityId, airdropTemplate, onExit }: { isManager?: boolean, defaultEntityType?: string, isCreatingEntity?: boolean, entityId?: string, airdropTemplate?: AirdropTemplate, onExit: () => void }) {
    const {config} = useConfig()
    const [airdropTemplateState, setAirdropTemplateState] = useState<AirdropTemplate | null>(airdropTemplate || null)
    const [currentEditingSetting, setCurrentEditingSetting] = useState<string | null>(null)
    const [settings, setSettings] = useState<AirdropTemplateSettings>({
        image: airdropTemplate?.settings.image || "",
        label: airdropTemplate?.settings.label || "",
        cronSchedule: airdropTemplate?.settings.cronSchedule || "",
        item: airdropTemplate?.settings.item || "",
        radius: airdropTemplate?.settings.radius || 0,
        spawnRadiusMultiplier: airdropTemplate?.settings.spawnRadiusMultiplier || 0,
        dropBlipEnabled: airdropTemplate?.settings.dropBlipEnabled || false,
        radiusBlipEnabled: airdropTemplate?.settings.radiusBlipEnabled || false,
        dropModel: airdropTemplate?.settings.dropModel || "",
        minidropModel: airdropTemplate?.settings.minidropModel || "",
        items: airdropTemplate?.settings.items || [],
        itemRange: airdropTemplate?.settings.itemRange || [],
        containers: airdropTemplate?.settings.containers || 0,
    })
    const startExit = () => {
        fetchNui("highlightAirdropTemplateEntity", {})
        onExit()
    }
    useNuiEvent("updateAirdropTemplateSetting", (data: any) => {
        if (!airdropTemplateState || data.airdropTemplateId !== airdropTemplateState.id) return;
        setAirdropTemplateState((prev) => {
            if (prev) {
                return {
                    ...prev,
                    settings: {
                        ...prev.settings,
                        [data.variable]: data.value,
                    },
                }
            }
            return null
        });
        setSettings((prev) => {
            return {
                ...prev,
                [data.variable]: data.value,
            }
        });
    });
    useNuiEvent("updateAirdropTemplateEntities", (data: any) => {
        if (!airdropTemplateState || data.airdropTemplateId !== airdropTemplateState.id) return;
        setAirdropTemplateState((prev) => {
            if (prev) {
                return {
                    ...prev,
                    entities: data.entities,
                }
            }
            return null
        });
    });
    useNuiEvent("updateAirdropTemplateOwner", (data: any) => {
        if (!airdropTemplateState || data.airdropTemplateId !== airdropTemplateState.id) return;
        setAirdropTemplateState((prev) => {
            if (prev) {
                return {
                    ...prev,
                    owner_info: data.owner_info,
                }
            }
            return null
        });
    });
    return (
        <>
            aaaa
        </>
    )
}

function Creator({ defaultAirdropTemplates }: { defaultAirdropTemplates: AirdropTemplate[] }) {
    const {config} = useConfig()
    const [currentAirdropTemplateId, setCurrentAirdropTemplateId] = useState<number | null>(null)
    const [airdropTemplates, setAirdropTemplates] = useState<AirdropTemplate[]>(defaultAirdropTemplates)
    const currentAirdropTemplate: AirdropTemplate | null = airdropTemplates.find(airdropTemplate => airdropTemplate.id === currentAirdropTemplateId) || null
    const [creatingAirdropTemplate, setCreatingAirdropTemplate] = useState(false)
    useNuiEvent("updateAirdropTemplates", (data: any) => {
        setAirdropTemplates(data.airdropTemplates)
    });
    return (
        <>
            {(currentAirdropTemplate || creatingAirdropTemplate) && (
            <AirdropTemplateDisplay airdropTemplate={currentAirdropTemplate!} onExit={() => {
                    setCurrentAirdropTemplateId(null)
                    setCreatingAirdropTemplate(false)
                }}/>
            )}
            {(!currentAirdropTemplate && !creatingAirdropTemplate) && (
                <>
                    <div className="px-2 pb-2 font-semibold text-2xl">AirdropTemplates</div>
                    <hr/>
                    <div className="flex flex-col pt-4 gap-2 overflow-auto max-h-[950px] px-2">
                        <Button variant="secondary" className="w-full hover:scale-95 transition-all duration-200" onClick={() => setCreatingAirdropTemplate(true)}>
                            <Plus size={16} />
                            <Translate id="airdrop_template_create"/>
                        </Button>   
                        {airdropTemplates.map((airdropTemplate) => (
                            <div key={airdropTemplate.id} className="p-4 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => setCurrentAirdropTemplateId(airdropTemplate.id)}>
                                <div className="flex flex-row items-center justify-between">
                                    <h2 className="text-md font-bold">{airdropTemplate.settings.label}</h2>
                                    <p className="text-sm text-zinc-400"><Translate id="airdrop_template_id" args={[airdropTemplate.id]}/></p>
                                </div>
                            </div> 
                        ))}
                    </div>
                </>
            )}
            <div className="position absolute bottom-0 left-[50%] translate-x-[-50%] w-full h-[50px] bg-secondary/50 flex items-center justify-center gap-2">
                <div className="font-semibold">&copy; Pickle Mods</div>
            </div>
        </>
    )
}

export default function CreatorDisplay() {
    const [visible, setVisible] = useState(false)
    const [airdropTemplates, setAirdropTemplates] = useState<AirdropTemplate[]>([])
    const [focus, setFocus] = useState(false)
    const [hidden, setHidden] = useState(true)
    const [airdropTemplateId, setAirdropTemplateId] = useState<number | null>(null)
    const [entityId, setEntityId] = useState<string | null>(null)
    const [creatingEntity, setCreatingEntity] = useState(false)
    const [entityType, setEntityType] = useState<string | null>(null)
    useNuiEvent("setEditorHidden", (data: any) => {
        setHidden(data.hidden)
    });
    useNuiEvent("updateAirdropTemplates", (data: any) => {
        setAirdropTemplates(data.airdropTemplates)
    });
    useNuiEvent("updateAirdropTemplateEntities", (data: any) => {
        setAirdropTemplates((prev) => {
            return prev.map((airdropTemplate) => {
                if (airdropTemplate.id === data.airdropTemplateId) {
                    return {
                        ...airdropTemplate,
                        entities: data.entities,
                    }
                }
                return airdropTemplate
            })
        })
    });
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement) return;
            if (!visible) return;
            if (event.key === "Escape" || event.key === "Backspace") {
                fetchNui("exitAirdropTemplateEditor", {});
            }
            if (event.key === "g") {
                fetchNui("disableEditorFocus", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    useNuiEvent("setEditorFocus", (data: any) => {
        setFocus(data.toggle)
    });

    useNuiEvent("openAirdropTemplateEditor", (data: any) => {
        setAirdropTemplates(data.airdropTemplates)
        setAirdropTemplateId(data.airdropTemplateId || null)
        setEntityId(data.editorData.entityId || null)
        setCreatingEntity(data.editorData.isCreatingEntity || false)
        setEntityType(data.editorData.entityType || null)
        setHidden(true)
        setVisible(true)
        setTimeout(() => {
            setHidden(false)
        }, 50)
    });
    useNuiEvent("closeAirdropTemplateEditor", () => {
        setHidden(true)
        setFocus(false)
        setTimeout(() => {
            setVisible(false)
        }, 300)
    });
    return (
        <>
            
            {(visible && !hidden) && <AppControls controls={[{key: "G", label: <Translate id={"focus_" + (focus ? "off" :  "on")}/>}]} />}
            {visible && (
                <div className="absolute top-0 left-0 w-full h-full overflow-hidden">
                    <div
                        className={`relative ml-auto px-2 py-2 w-[400px] h-full bg-background/95 transition-transform duration-300 ${
                        hidden ? "translate-x-full" : "translate-x-0"
                        }`}
                    > 
                    {airdropTemplateId ? (
                        <AirdropTemplateDisplay isManager={true} airdropTemplate={airdropTemplates.find(airdropTemplate => airdropTemplate.id === airdropTemplateId)} defaultEntityType={entityType || undefined} isCreatingEntity={creatingEntity} entityId={entityId || undefined} onExit={() => {
                            fetchNui("exitAirdropTemplateEditor", {})
                        }}/>
                    ) : (
                        <Creator defaultAirdropTemplates={airdropTemplates} />
                    )}
                    </div>
                </div>  
            )}
        </>
    )
}