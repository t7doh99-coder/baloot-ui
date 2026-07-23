import { ChestIcon } from "./components/ChestIcon";
import { FlameIcon } from "./components/FlameIcon";

export default function App() {
  return (
    <div className="size-full flex items-center justify-center" style={{ background: "#0F0620" }}>
      <div className="flex flex-row items-center gap-10">
        <ChestIcon size={280} />
        <FlameIcon size={200} />
      </div>
    </div>
  );
}
