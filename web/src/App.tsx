import CookingInterface from "./components/AirdropContainer/AirdropContainer"
import { useConfig } from "./providers/config";

export function GetItemLabel(item: string) {
  const { config } = useConfig();
  const itemLabel = config.items[item]?.label;
  if (!itemLabel) {
    return item;
  }
  return itemLabel;
}

export function GetItemImage(item: string) {
  const { config } = useConfig();
  return config.imageDirectory ? `${config.imageDirectory}/${item}.png` : `/nui/images/${item}.png`;
}

function App() {
  return (
    <div className="dark w-screen h-screen absolute text-primary top-0 left-0">
      <CookingInterface />
    </div>
  )
}

export default App;
