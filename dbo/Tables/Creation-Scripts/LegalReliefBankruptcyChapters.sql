SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalReliefBankruptcyChapters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Chapter] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[Date] [date] NULL,
	[Active] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalReliefId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalReliefBankruptcyChapters]  WITH CHECK ADD  CONSTRAINT [ELegalRelief_LegalReliefBankruptcyChapters] FOREIGN KEY([LegalReliefId])
REFERENCES [dbo].[LegalReliefs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalReliefBankruptcyChapters] CHECK CONSTRAINT [ELegalRelief_LegalReliefBankruptcyChapters]
GO
