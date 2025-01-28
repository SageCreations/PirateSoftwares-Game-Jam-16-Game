package Sound_Test 

import rl "vendor:raylib"
import "core:fmt"
import "core:c"

main :: proc() {
  
  SCREEN_WIDTH :: 1280 
  SCREEN_HEIGHT :: 720
 
  rl.InitWindow( SCREEN_WIDTH ,SCREEN_HEIGHT, "Raylib Testing Audio Control" )
  
  rl.InitAudioDevice()

  music : rl.Music = rl.LoadMusicStream("CongratsMusicGame.wav")
  music.looping = false 
  volume: c.float = 1.0

  rl.PlayMusicStream(music)

  is_paused : bool = false

  rl.SetTargetFPS(60)
  
  for !rl.WindowShouldClose(){
      
      rl.UpdateMusicStream(music)

      if rl.IsKeyPressed(.P){
          is_paused = !is_paused
          if is_paused{
              rl.PauseMusicStream(music)
            }
          else{
              rl.ResumeMusicStream(music)
          }
      }
      if rl.IsKeyDown(.DOWN){
        volume -= 0.1
      }
      else if rl.IsKeyDown(.UP){
            volume += 0.1
      }

      if volume >= 1.0 {
          volume = 1.0
        }
      else if volume <= 0.0{
          volume = 0.0
        }
        
      rl.SetMusicVolume(music,volume)
      rl.BeginDrawing()
      rl.ClearBackground(rl.RAYWHITE)
        
      rl.DrawRectangle(20,20,425,145,rl.WHITE)
      rl.DrawRectangleLines(20,20,425,145,rl.GRAY)
      rl.DrawText("Press LEFT/DOWN To Lower Volume",40,50,20,rl.BLACK)
      rl.DrawText("Press RIGHT/UP To Raise Volume",40,100,20,rl.BLACK)
      rl.DrawText(rl.TextFormat("Current Audio Level Set at : %f",volume),40,150,20,rl.BLACK)
      rl.EndDrawing()
     }
      
      rl.UnloadMusicStream(music)
      rl.CloseAudioDevice()
      rl.CloseWindow()

}

