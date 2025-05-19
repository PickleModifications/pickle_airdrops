import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from './nui/useNui';

export type Config = {
    identifier: string;
    imageDirectory?: string;
    locale?: Record<string, string>;
    countryCode?: string;
    currency?: string;
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
        locale: {
            "airdrop_container_desc": "Click on the items to take them from the airdrop container.",
            "controls_exit": "Return to Game",
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