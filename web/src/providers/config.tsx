import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from './nui/useNui';
import { CookingComponent } from '@/components/AirdropContainer/AirdropContainer';

export type Config = {
    identifier: string;
    imageDirectory?: string;
    locale?: Record<string, string>;
    countryCode?: string;
    currency?: string;
    showMissingComponents: boolean;
    cookingComponents: {
        [key: string]: CookingComponent;
    };
    items: {
        [key: string]: {
            label: string;
        };
    };
}

interface ConfigContextProps {
    config: Config;
    setConfig: (config: Config) => void;
}

const ConfigContext = createContext<ConfigContextProps | undefined>(undefined);

export const ConfigProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [config, setConfig] = useState<Config>({
        imageDirectory: undefined,
        identifier: "ERR_NO_IDENTIFIER",
        currency: "GBP",
        countryCode: "en-GB",
        showMissingComponents: true,
        cookingComponents: {
            // "lettuce": {
            //     categories: ["Vegetables"],
            //     model: `npds_pres_lettuce`,
            //     height: 0.005,
            // },
            // "tomatoslice": {
            //     categories: ["Vegetables"],
            //     model: `npds_pres_tomatoslice`,
            //     height: 0.025,
            //     surfaceOffset: 0.015,
            // },
            // "grilledpatty": {
            //     categories: ["Meat"],
            //     model: `npds_pres_grilledpatty`,
            //     height: 0.0125,
            // },
            // "rawpatty": {
            //     categories: ["Meat"],
            //     model: `npds_pres_rawpatty`,
            //     height: 0.0125,
            // },
            // "smoltedcheese": {
            //     categories: ["Dairy & Cheese"],
            //     model: `npds_pres_smoltedcheese`,
            //     surfaceOffset: 0.0125,
            // },
            // "topbun": {
            //     categories: ["Bread & Wheat"],
            //     model: `npds_pres_topbun`,
            //     surfaceOffset: 0.0125,
            // },
            // "botbun": {
            //     categories: ["Bread & Wheat"],
            //     model: `npds_pres_botbun`,
            // },
        },
        items: {
            // "lettuce": {label: "Lettuce"},
            // "tomatoslice": {label: "Tomato Slice"},
            // "grilledpatty": {label: "Grilled Patty"},
            // "rawpatty": {label: "Raw Patty"},
            // "smoltedcheese": {label: "Smolted Cheese"},
            // "topbun": {label: "Top Bun"},
            // "botbun": {label: "Bottom Bun"},
        },
    });
    useNuiEvent('setConfig', (data) => {
        setConfig({ ...config, ...data.config });
    });
    return (
        <ConfigContext.Provider value={{ config, setConfig }}>
            {children}
        </ConfigContext.Provider>
    );
};

export const useConfig = (): ConfigContextProps => {
    const context = useContext(ConfigContext);
    if (!context) {
        throw new Error('useConfig must be used within a ConfigProvider');
    }
    return context;
};