import { Menu } from "lucide-react";
import {
  createContext,
  forwardRef,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import type {
  ButtonHTMLAttributes,
  ComponentProps,
  HTMLAttributes,
} from "react";

import { Button } from "./button";
import { Sheet, SheetContent } from "./sheet";
import { cn } from "./utils";

type SidebarContextValue = {
  isMobile: boolean;
  open: boolean;
  openMobile: boolean;
  setOpenMobile: (open: boolean) => void;
  toggleSidebar: () => void;
};

const SidebarContext = createContext<SidebarContextValue | null>(null);

export const useSidebar = () => {
  const context = useContext(SidebarContext);
  if (!context) {
    throw new Error("useSidebar must be used within a SidebarProvider.");
  }
  return context;
};

export const useIsMobile = () => {
  const [isMobile, setIsMobile] = useState(
    () => matchMedia("(max-width: 767px)").matches,
  );
  useEffect(() => {
    const media = matchMedia("(max-width: 767px)");
    const update = () => setIsMobile(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  return isMobile;
};

export const SidebarProvider = ({
  children,
  defaultOpen = true,
  ...props
}: HTMLAttributes<HTMLDivElement> & { defaultOpen?: boolean }) => {
  const [open, setOpen] = useState(defaultOpen);
  const [openMobile, setOpenMobile] = useState(false);
  const isMobile = useIsMobile();
  const value = useMemo(
    () => ({
      isMobile,
      open,
      openMobile,
      setOpenMobile,
      toggleSidebar: () =>
        isMobile
          ? setOpenMobile((current) => !current)
          : setOpen((current) => !current),
    }),
    [isMobile, open, openMobile],
  );
  return (
    <SidebarContext.Provider value={value}>
      <div className="flex h-dvh min-h-0 w-full" {...props}>
        {children}
      </div>
    </SidebarContext.Provider>
  );
};

export const Sidebar = ({
  children,
  className,
}: HTMLAttributes<HTMLDivElement>) => {
  const { isMobile, open, openMobile, setOpenMobile } = useSidebar();
  const content = <div className="flex h-full w-full flex-col">{children}</div>;
  if (isMobile) {
    return (
      <Sheet onOpenChange={setOpenMobile} open={openMobile}>
        <SheetContent className={cn("p-0", className)} side="right">
          {content}
        </SheetContent>
      </Sheet>
    );
  }
  return (
    <div
      className="group peer hidden md:block"
      data-state={open ? "expanded" : "collapsed"}
    >
      <div className="h-dvh w-64 transition-[width] duration-200 group-data-[state=collapsed]:w-10" />
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-10 hidden w-64 border-r bg-background transition-[width] duration-200 md:flex group-data-[state=collapsed]:w-10",
          className,
        )}
      >
        {content}
      </aside>
    </div>
  );
};

export const SidebarInset = forwardRef<HTMLElement, ComponentProps<"main">>(
  ({ className, ...props }, ref) => (
    <main
      className={cn("relative flex min-w-0 flex-1 flex-col", className)}
      ref={ref}
      {...props}
    />
  ),
);

SidebarInset.displayName = "SidebarInset";

export const SidebarTrigger = forwardRef<
  HTMLButtonElement,
  ButtonHTMLAttributes<HTMLButtonElement>
>(({ className, onClick, ...props }, ref) => {
  const { children, ...buttonProps } = props;
  const { toggleSidebar } = useSidebar();
  return (
    <Button
      aria-label="Toggle tmux sessions sidebar"
      className={className}
      onClick={(event) => {
        onClick?.(event);
        toggleSidebar();
      }}
      ref={ref}
      size="icon"
      variant="ghost"
      {...buttonProps}
    >
      {children ? (
        <span aria-hidden="true">{children}</span>
      ) : (
        <Menu aria-hidden="true" className="size-5" />
      )}
    </Button>
  );
});

SidebarTrigger.displayName = "SidebarTrigger";

export const SidebarHeader = forwardRef<
  HTMLDivElement,
  HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    className={cn("flex items-center justify-between gap-2 p-3", className)}
    ref={ref}
    {...props}
  />
));

SidebarHeader.displayName = "SidebarHeader";

export const SidebarContent = forwardRef<
  HTMLDivElement,
  HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    className={cn("min-h-0 flex-1 overflow-y-auto p-2", className)}
    ref={ref}
    {...props}
  />
));

SidebarContent.displayName = "SidebarContent";

export const SidebarFooter = forwardRef<
  HTMLDivElement,
  HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div className={cn("border-t p-3 text-sm", className)} ref={ref} {...props} />
));

SidebarFooter.displayName = "SidebarFooter";

export const SidebarMenu = forwardRef<HTMLUListElement, ComponentProps<"ul">>(
  ({ className, ...props }, ref) => (
    <ul className={cn("grid gap-1", className)} ref={ref} {...props} />
  ),
);

SidebarMenu.displayName = "SidebarMenu";

export const SidebarMenuItem = forwardRef<HTMLLIElement, ComponentProps<"li">>(
  (props, ref) => <li ref={ref} {...props} />,
);

SidebarMenuItem.displayName = "SidebarMenuItem";

export const SidebarMenuButton = forwardRef<
  HTMLButtonElement,
  ButtonHTMLAttributes<HTMLButtonElement> & { isActive?: boolean }
>(({ className, isActive = false, ...props }, ref) => (
  <button
    className={cn(
      "flex min-h-[2.375rem] w-full items-center truncate border-l-4 border-transparent px-3 py-2 text-left text-sm leading-5 hover:bg-panel-muted",
      isActive && "border-accent bg-accent/15 font-bold text-accent",
      className,
    )}
    aria-current={isActive ? "page" : undefined}
    data-active={isActive}
    ref={ref}
    type="button"
    {...props}
  />
));

SidebarMenuButton.displayName = "SidebarMenuButton";
