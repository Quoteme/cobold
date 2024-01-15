/*
 * sdlshim.c : I/O only. draw : Frame -> (); sdl_mask_solid : World x Z x Z
 * -> B. Layers h < {coin, goal, player} < v, all pixel-aligned.
 */
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>

static SDL_Window   *g_window      = NULL;
static SDL_Renderer *g_renderer    = NULL;
static SDL_Texture  *g_hintergrund = NULL;
static SDL_Texture  *g_vordergrund = NULL;
static SDL_Texture  *g_player      = NULL;
static SDL_Surface  *g_kollision   = NULL; /* CPU-side; never rendered */

static int g_cam_x  = 0;
static int g_cam_y  = 0;
static int g_win_w  = 1024;
static int g_win_h  = 576;
static int g_world_w = 0;
static int g_world_h = 0;

/* zoom := win / view */
static int g_view_w = 1024;
static int g_view_h = 576;

static double zoom_x(void) { return (double)g_win_w / g_view_w; }
static double zoom_y(void) { return (double)g_win_h / g_view_h; }

/* atlas : (state, frame) -> Rect, lifted from bildbesucher/player.mjs */
static const SDL_Rect IDLE_FRAMES[3] = {
    {7, 5, 17, 45}, {38, 5, 17, 45}, {66, 4, 17, 46}
};
static const SDL_Rect WALK_FRAMES[6] = {
    {0, 61, 27, 46}, {29, 61, 24, 45}, {56, 57, 32, 49},
    {91, 56, 20, 50}, {113, 60, 29, 45}, {142, 57, 28, 48}
};

void sdl_init(int *rc, int *win_w, int *win_h, int *world_w, int *world_h)
{
    *rc = 0;
    if (SDL_Init(SDL_INIT_VIDEO) != 0) { *rc = 1; return; }
    if (!(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG)) { *rc = 2; return; }

    g_window = SDL_CreateWindow("COBOLD - a jump-and-run ledger",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        g_win_w, g_win_h, SDL_WINDOW_SHOWN);
    if (!g_window) { *rc = 3; return; }

    g_renderer = SDL_CreateRenderer(g_window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!g_renderer) { *rc = 4; return; }

    g_hintergrund = IMG_LoadTexture(g_renderer, "assets/landschaft-h.png");
    if (!g_hintergrund) { fprintf(stderr, "load(h): %s\n", IMG_GetError()); *rc = 5; return; }

    g_vordergrund = IMG_LoadTexture(g_renderer, "assets/landschaft-v.png");
    if (!g_vordergrund) { fprintf(stderr, "load(v): %s\n", IMG_GetError()); *rc = 6; return; }
    SDL_SetTextureBlendMode(g_vordergrund, SDL_BLENDMODE_BLEND);

    g_player = IMG_LoadTexture(g_renderer, "assets/player.png");
    if (!g_player) { fprintf(stderr, "load(player): %s\n", IMG_GetError()); *rc = 7; return; }
    SDL_SetTextureBlendMode(g_player, SDL_BLENDMODE_BLEND);

    SDL_Surface *raw_k = IMG_Load("assets/landschaft-k.png");
    if (!raw_k) { fprintf(stderr, "load(k): %s\n", IMG_GetError()); *rc = 8; return; }
    g_kollision = SDL_ConvertSurfaceFormat(raw_k, SDL_PIXELFORMAT_RGBA32, 0);
    SDL_FreeSurface(raw_k);
    if (!g_kollision) { *rc = 9; return; }

    g_world_w = g_kollision->w;
    g_world_h = g_kollision->h;
    *win_w = g_win_w;
    *win_h = g_win_h;
    *world_w = g_world_w;
    *world_h = g_world_h;
}

/* solid(x,y) := opaque(mask[x,y]); false outside the mask's own bounds */
void sdl_mask_solid(int *x, int *y, int *solid)
{
    *solid = 0;
    if (!g_kollision) return;
    if (*x < 0 || *x >= g_world_w || *y < 0 || *y >= g_world_h) return;

    Uint8 *row = (Uint8 *)g_kollision->pixels + (*y) * g_kollision->pitch;
    Uint32 pixel = ((Uint32 *)row)[*x];
    Uint8 r, g, b, a;
    SDL_GetRGBA(pixel, g_kollision->format, &r, &g, &b, &a);
    *solid = (a > 128) ? 1 : 0;
}

void sdl_poll(int *quit, int *left, int *right, int *jump)
{
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
        if (ev.type == SDL_QUIT) *quit = 1;
        if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_ESCAPE) *quit = 1;
    }
    const Uint8 *ks = SDL_GetKeyboardState(NULL);
    *left  = (ks[SDL_SCANCODE_LEFT]  || ks[SDL_SCANCODE_A]) ? 1 : 0;
    *right = (ks[SDL_SCANCODE_RIGHT] || ks[SDL_SCANCODE_D]) ? 1 : 0;
    *jump  = (ks[SDL_SCANCODE_UP] || ks[SDL_SCANCODE_W] || ks[SDL_SCANCODE_SPACE]) ? 1 : 0;
}

void sdl_delay(int *ms) { SDL_Delay((Uint32)*ms); }

void sdl_begin_frame(int *cam_x, int *cam_y, int *view_w, int *view_h)
{
    g_cam_x = *cam_x;
    g_cam_y = *cam_y;
    g_view_w = *view_w;
    g_view_h = *view_h;
    SDL_SetRenderDrawColor(g_renderer, 235, 244, 255, 255);
    SDL_RenderClear(g_renderer);
    SDL_Rect src = {g_cam_x, g_cam_y, g_view_w, g_view_h};
    SDL_Rect dst = {0, 0, g_win_w, g_win_h};
    SDL_RenderCopy(g_renderer, g_hintergrund, &src, &dst);
}

void sdl_draw_coin(int *x, int *y)
{
    SDL_Rect r = {
        (int)((*x - g_cam_x) * zoom_x()), (int)((*y - g_cam_y) * zoom_y()),
        (int)(16 * zoom_x()), (int)(16 * zoom_y())
    };
    SDL_SetRenderDrawColor(g_renderer, 234, 179, 8, 255);
    SDL_RenderFillRect(g_renderer, &r);
    SDL_SetRenderDrawColor(g_renderer, 161, 98, 7, 255);
    SDL_RenderDrawRect(g_renderer, &r);
}

void sdl_draw_goal(int *x, int *y, int *w, int *h)
{
    double zx = zoom_x(), zy = zoom_y();
    SDL_Rect pole = {
        (int)((*x - g_cam_x) * zx), (int)((*y - g_cam_y) * zy),
        (int)(6 * zx), (int)(*h * zy)
    };
    SDL_SetRenderDrawColor(g_renderer, 68, 64, 60, 255);
    SDL_RenderFillRect(g_renderer, &pole);
    SDL_Rect flag = {
        (int)((*x - g_cam_x + 6) * zx), (int)((*y - g_cam_y) * zy),
        (int)((*w - 6) * zx), (int)((*h / 3) * zy)
    };
    SDL_SetRenderDrawColor(g_renderer, 220, 38, 38, 255);
    SDL_RenderFillRect(g_renderer, &flag);
}

/* state in {0=idle,1=walk}, facing in {0=right,1=left}; drawn at src/2 . zoom */
void sdl_draw_player(int *x, int *y, int *anim_state, int *anim_frame, int *facing)
{
    double zx = zoom_x(), zy = zoom_y();
    SDL_Rect src = (*anim_state == 1) ? WALK_FRAMES[*anim_frame] : IDLE_FRAMES[*anim_frame];
    SDL_Rect dst = {
        (int)((*x - g_cam_x) * zx), (int)((*y - g_cam_y) * zy),
        (int)((src.w / 2) * zx), (int)((src.h / 2) * zy)
    };
    SDL_RendererFlip flip = (*facing == 1) ? SDL_FLIP_HORIZONTAL : SDL_FLIP_NONE;
    SDL_RenderCopyEx(g_renderer, g_player, &src, &dst, 0.0, NULL, flip);
}

/* drawn last: occludes the player, as Kamera.render() layers vordergrund */
void sdl_draw_foreground(void)
{
    SDL_Rect src = {g_cam_x, g_cam_y, g_view_w, g_view_h};
    SDL_Rect dst = {0, 0, g_win_w, g_win_h};
    SDL_RenderCopy(g_renderer, g_vordergrund, &src, &dst);
}

void sdl_end_frame(int *balance, int *overdrafts)
{
    char title[128];
    snprintf(title, sizeof(title),
        "COBOLD Ledger  |  Balance: %09d  |  Overdrafts: %d  (Esc to quit)",
        *balance, *overdrafts);
    SDL_SetWindowTitle(g_window, title);
    SDL_RenderPresent(g_renderer);
}

void sdl_shutdown(void)
{
    if (g_kollision) SDL_FreeSurface(g_kollision);
    if (g_player) SDL_DestroyTexture(g_player);
    if (g_vordergrund) SDL_DestroyTexture(g_vordergrund);
    if (g_hintergrund) SDL_DestroyTexture(g_hintergrund);
    if (g_renderer) SDL_DestroyRenderer(g_renderer);
    if (g_window) SDL_DestroyWindow(g_window);
    IMG_Quit();
    SDL_Quit();
}
