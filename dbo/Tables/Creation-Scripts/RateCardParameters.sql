SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RateCardParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ParameterNumber] [int] NOT NULL,
	[IsBlankAllowed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RateCardId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ProgramParameterId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RateCardParameters]  WITH CHECK ADD  CONSTRAINT [ERateCard_RateCardParameters] FOREIGN KEY([RateCardId])
REFERENCES [dbo].[RateCards] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RateCardParameters] CHECK CONSTRAINT [ERateCard_RateCardParameters]
GO
ALTER TABLE [dbo].[RateCardParameters]  WITH CHECK ADD  CONSTRAINT [ERateCardParameter_ProgramParameter] FOREIGN KEY([ProgramParameterId])
REFERENCES [dbo].[ProgramParameterConfigs] ([Id])
GO
ALTER TABLE [dbo].[RateCardParameters] CHECK CONSTRAINT [ERateCardParameter_ProgramParameter]
GO
